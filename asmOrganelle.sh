#!/bin/bash

#$ -q all.q
#$ -cwd
#$ -pe smp 10

module load minimap2
module load miniasm
module load racon
module load mira/4.9.6


#=Check required Software=
source ./asmOrganelle_reqSoft.sh
#=Global Variables=
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


##############################################
##############################################
##############################################
LOG_DIR=logs_asmOrganlle
mkdir -p ${LOG_DIR}
LOG_FILE=${LOG_DIR}/${PREFIX}.asmOrganelle.log

for baitIter in $(seq 1 $NUMBER_ITER_BAIT); do
 #===Define Variables for iteration===
 PREV_ITER=$((baitIter - 1))
 PREFIX_ITER=${PREFIX}.MIRABAITiter${baitIter}
 PREFIX_PREV_ITER=${PREFIX}.MIRABAITiter${PREV_ITER}
 BAIT_READS=${PREFIX_ITER}.bait.fasta
 PAF=${PREFIX_ITER}.paf.gz
 GFA=${PREFIX_ITER}.gfa.gz
 CONTIGS=${PREFIX_ITER}.miniasm.fasta.gz
 LOG_BAIT=${LOG_DIR}/${PREFIX_ITER}.bait.log
 LOG_OVERLAP=${LOG_DIR}/${PREFIX_ITER}.minimap2.log
 LOG_ASM=${LOG_DIR}/${PREFIX_ITER}.miniasm.log
 #===Select Reference Dataset===
 # Only in the first bait iteration we will use an external fasta database (a collection of organelle (either mito or plastid) genomes.
 # Further iteration will use the Racon contigs as reference, to bait for new reads.
 if [ "$baitIter" -eq 1 ]; then 
  REFERENCE=${EXTERNAL_REFERENCE}
 else
  REFERENCE=${PREFIX_PREV_ITER}.racon.${NUMBER_ITER_CNS}.fasta
 fi
 echo $baitIter $PREFIX_ITER $REFERENCE >> ${LOG_FILE}
 #===Running baiting step===
 echo Running MIRABAIT iteration $baitIter DATE: `date` >> ${LOG_FILE}
 if [ ! -f ${BAIT_READS}.gz ]; then 
  mirabait -d -n $NUMBER_KMERS -o $BAIT_READS -b $REFERENCE  -t $NSLOTS -l 0 $ALL_READS > $LOG_BAIT 2>&1 
  pigz -p $NSLOTS $BAIT_READS
 fi
 echo Found `gunzip -c ${BAIT_READS}.gz |grep -c ">" ` bait reads in ${BAIT_READS}.gz >> ${LOG_FILE}
 echo Finished running MIRABAIT iteration $baitIter DATE: `date` >> ${LOG_FILE}
 #===Finding Overlaps among reads
 echo Running MINIMAP2 iteration $baitIter DATE: `date` >> ${LOG_FILE}
 minimap2 -t $NSLOTS -x ava-pb ${BAIT_READS}.gz ${BAIT_READS}.gz 2> $LOG_OVERLAP |pigz -p $NSLOTS > $PAF
 echo Finished running MINIMAP2 iteration $baitIter DATE: `date` >> ${LOG_FILE}
 #===Assemblying reads based on overlaps
 echo Running MINIASM iteration $baitIter DATE: `date` >> ${LOG_FILE}
 miniasm -f ${BAIT_READS}.gz $PAF 2> ${LOG_ASM} |pigz -p $NSLOTS > $GFA 
 gunzip -c $GFA |awk '/^S/{print ">"$2"\n"$3}' | fold |pigz -p $NSLOTS > $CONTIGS
 echo Finished running MINIASM iteration $baitIter DATE: `date` >> ${LOG_FILE}
 #===Calling consensus sequences, doing several iterations :  NUMBER_ITER_CNS
 for cnsIter in $(seq 1 $NUMBER_ITER_CNS); do
  POLISHEDCONTIGS=${PREFIX_ITER}.racon.${cnsIter}.fasta
  PREV_RACONITER=$((cnsIter - 1))
  SAM=${PREFIX_ITER}.minimap2.${cnsIter}.sam
  LOG_SAM=${LOG_DIR}/${PREFIX_ITER}.minimap2.${cnsIter}.sam.log
  LOG_RACON=${LOG_DIR}/${PREFIX_ITER}.racon.${cnsIter}.log
  if [ "$cnsIter" -eq 1 ]; then
   CONTIGS=${CONTIGS}
  else
   CONTIGS=${PREFIX_ITER}.racon.${PREV_RACONITER}.fasta
  fi
  echo Running RACON iteration $baitIter polishing iteration $cnsIter DATE: `date` >> ${LOG_FILE}
  minimap2 -ax map-pb $CONTIGS ${BAIT_READS}.gz  > $SAM 2> ${LOG_SAM}
  racon --threads $NSLOTS ${BAIT_READS}.gz $SAM $CONTIGS > $POLISHEDCONTIGS 2> ${LOG_RACON}
  rm $SAM
  echo Finished running RACON iteration $baitIter polishing iteration $cnsIter DATE: `date` >> ${LOG_FILE}
 done
done

#DMRPITERMIRABAIT=iter1
#DMRPPREFIX=Vintermedia_ChloroplastMaizeRice.MIRABAIT${ITERMIRABAIT}
#DMRPREFERENCES=../References/Maize_Rice_plastid.fasta
#DMRPALLREADS=../all.Vintermedia.fasta
#DMRPREADS=bait_${PREFIX}.fasta
#DMRPPAF=${PREFIX}.paf.gz
#DMRPGFA=${PREFIX}.gfa.gz
#DMRPCONTIGS=${PREFIX}.miniasm.fasta.gz
#DMRPPOLISHEDCONTIGS=${PREFIX}.racon.1.fasta
#DMRPSAM=${PREFIX}.map.sam

#DMRPmirabait -d -n 10 -o $READS -b $REFERENCES  -t $NSLOTS -l 0 $ALLREADS
#DMRPminimap2 -t $NSLOTS -x ava-pb $READS $READS |pigz -p $NSLOTS > $PAF
#DMRPminiasm -f $READS $PAF |pigz -p $NSLOTS > $GFA 
#DMRPgunzip -c $GFA |awk '/^S/{print ">"$2"\n"$3}' | fold |pigz -p $NSLOTS > $CONTIGS
#DMRPminimap2 -ax map-pb $CONTIGS $READS  > $SAM
#DMRPracon --threads $NSLOTS $READS $SAM $CONTIGS > $POLISHEDCONTIGS
#DMRP
#DMRPfor i in  $(seq 2 4); do
#DMRP echo $i
#DMRP CONTIGS=$POLISHEDCONTIGS
#DMRP POLISHEDCONTIGS=${POLISHEDCONTIGS/.racon.?.fasta/.racon.$i.fasta}
#DMRP echo ITER:$i $CONTIGS $POLISHEDCONTIGS
#DMRP minimap2 -ax map-pb $CONTIGS $READS  > $SAM
#DMRP racon --threads $NSLOTS $READS $SAM $CONTIGS > $POLISHEDCONTIGS
#DMRPdone
#DMRP
#DMRPfor iter in $(seq 2 5); do
#DMRP echo MiraIter: $iter
#DMRP ITERMIRABAITI=iter${iter}
#DMRP PREFIXI=Vintermedia_ChloroplastMaizeRice.MIRABAIT${ITERMIRABAITI}
#DMRP PREVITER=$((iter - 1))
#DMRP REFERENCESI=Vintermedia_ChloroplastMaizeRice.MIRABAITiter${PREVITER}.racon.4.fasta
#DMRP READSI=bait_${PREFIXI}.fasta
#DMRP PAFI=${PREFIXI}.paf.gz
#DMRP GFAI=${PREFIXI}.gfa.gz
#DMRP CONTIGSI=${PREFIXI}.miniasm.fasta.gz
#DMRP POLISHEDCONTIGSI=${PREFIXI}.racon.1.fasta
#DMRP SAMI=${PREFIXI}.map.sam
#DMRP
#DMRP mirabait -d -n 10 -o $READSI -b $REFERENCESI  -t $NSLOTS -l 0 $ALLREADS
#DMRP minimap2 -t $NSLOTS -x ava-pb $READSI $READSI |pigz -p $NSLOTS > $PAFI
#DMRP miniasm -f $READSI $PAFI |pigz -p $NSLOTS > $GFAI
#DMRP gunzip -c $GFAI |awk '/^S/{print ">"$2"\n"$3}' | fold |pigz -p $NSLOTS > $CONTIGSI
#DMRP minimap2 -ax map-pb $CONTIGSI $READSI  > $SAMI
#DMRP racon --threads $NSLOTS $READSI $SAMI $CONTIGSI > $POLISHEDCONTIGSI
#DMRP
#DMRP for i in  $(seq 2 4); do
#DMRP  echo $i
#DMRP  CONTIGSI=$POLISHEDCONTIGSI
#DMRP  POLISHEDCONTIGSI=${POLISHEDCONTIGSI/.racon.?.fasta/.racon.$i.fasta}
#DMRP  echo ITER:$i $CONTIGSI $POLISHEDCONTIGSI
#DMRP  minimap2 -ax map-pb $CONTIGSI $READSI  > $SAMI
#DMRP  racon --threads $NSLOTS $READSI $SAMI $CONTIGSI > $POLISHEDCONTIGSI
#DMRP done
#DMRPdone
