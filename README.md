# asmOrganelle

Organelle Genome Assembly from PacBio reads

## Getting Started

asmOrganelle tries to assemble an organelle genome (mitochondria or chloroplast) from WGS PacBio reads.

### Steps

1. Fish reads from a WGS PacBio dataset by comparign against a reference dataset, using mirabait v4.9.6
2. Compute overlaps among the reads obtained in step 1, using minimap2
3. Fast assembly, with miniasm
4. Generate consensus sequence from assembly, using minimap2 and racon (racon wil run with 3 iterations, this is configurable)
5. Use consensus assembly as reference dataset and restart in step 1. Carry out 5 iterations (configurable).

### User-defined arguments

User-defined arguments MUST be supplied in the file asmOrganelle_config.sh
