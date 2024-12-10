import os
import torch
from torch.utils.data import DataLoader
from torch.distributed import destroy_process_group, init_process_group
from torch.distributed.fsdp import FullyShardedDataParallel as FSDP, MixedPrecision
from transformers import (
    AutoTokenizer,
    DataCollatorForLanguageModeling,
    LlamaConfig,
    LlamaForCausalLM,
)
from datasets import load_dataset
from datasets.distributed import split_dataset_by_node
from contextlib import nullcontext

# Hyperparameters
GLOBAL_BATCH_SIZE = 128
MICRO_BATCH_SIZE = 8
GRAD_ACCUMULATION_STEPS = GLOBAL_BATCH_SIZE // MICRO_BATCH_SIZE

# Initialize the distributed process group
def ddp_setup():
    init_process_group(backend="nccl")
    torch.cuda.set_device(int(os.environ["LOCAL_RANK"]))

def main():
    # Distributed environment variables
    local_rank = int(os.environ["LOCAL_RANK"])
    world_size = int(os.environ["WORLD_SIZE"])
    rank = int(os.environ["RANK"])

    # Model configuration and loading
    model_config = LlamaConfig.from_pretrained("PrimeIntellect/llama-150m-fresh")
    model = LlamaForCausalLM.from_pretrained(
        pretrained_model_name_or_path="PrimeIntellect/llama-150m-fresh", config=model_config
    )
    model = model.to("cuda")

    # Wrap the model with FSDP
    model = FSDP(
        model,
        mixed_precision=MixedPrecision(param_dtype=torch.bfloat16),
        use_orig_params=True,
    )

    # Optimizer
    optimizer = torch.optim.AdamW(model.parameters(), lr=0.001)

    # Tokenizer setup
    tokenizer = AutoTokenizer.from_pretrained("mistralai/Mistral-7B-v0.1", use_fast=True)
    tokenizer.pad_token = "</s>"

    # Tokenization function moved inside main()
    def tokenize_function(data):
        outputs = tokenizer(
            data["text"],
            truncation=True,
            max_length=1024,
            padding="max_length",
        )
        return outputs

    # Load and preprocess dataset
    ds = load_dataset("allenai/c4", "en", streaming=True)
    tokenized_datasets = ds.map(
        tokenize_function, batched=True, remove_columns=["text", "timestamp", "url"]
    )["train"]
    tokenized_datasets = split_dataset_by_node(
        tokenized_datasets, world_size=world_size, rank=rank
    )

    # Data collator and DataLoader setup
    data_collator = DataCollatorForLanguageModeling(tokenizer=tokenizer, mlm=False)
    train_loader = DataLoader(
        tokenized_datasets,
        collate_fn=data_collator,
        batch_size=MICRO_BATCH_SIZE,
        num_workers=4,
    )

    # Training loop
    for step, batch in enumerate(train_loader):
        is_accumulating = step % GRAD_ACCUMULATION_STEPS != 0

        # Move batch to GPU
        for key in batch.keys():
            batch[key] = batch[key].to("cuda")

        # Forward and backward pass
        with model.no_sync() if is_accumulating else nullcontext():
            outputs = model(**batch)
            loss = outputs.loss / GRAD_ACCUMULATION_STEPS
            loss.backward()

        # Optimizer step and reset gradients
        if not is_accumulating:
            optimizer.step()
            optimizer.zero_grad()

        print(f"Step: {step}, Loss: {loss.item()}")

if __name__ == "__main__":
    ddp_setup()
    main()
    destroy_process_group()
