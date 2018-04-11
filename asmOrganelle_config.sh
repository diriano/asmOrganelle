# Must be defined by the user

# Number of cores
NSLOTS=10

# Number of MIRABAIT runs
NUMBER_ITER_BAIT=5

# Number of kmers that must match to keep a hit
NUMBER_KMERS=10

# Number of Racon runs within each Mirabait run
NUMBER_ITER_CNS=3

# Dataset (fasta) containing all long reads
ALL_READS=../all.Vintermedia.fasta
#ALL_READS=bait_Vintermedia_ChloroplastMaizeRice.MIRABAITiter2.fasta

# Prefix for output files
PREFIX=Vintermedia_ChloroplastMaizeRice

# Fasta database with collection of  organelle genomes used as reference in the first bait iteration
EXTERNAL_REFERENCE=../References/Maize_Rice_plastid.fasta


