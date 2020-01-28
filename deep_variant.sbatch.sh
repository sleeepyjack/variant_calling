#!/bin/sh

# SLURM parameters (adjust according to your setup)
#SBATCH -J deep_variant
#SBATCH -A pararch
#SBATCH -p deeplearning
#SBATCH -t 04:00:00
#SBATCH -c 10
#SBATCH --mem=40GB
#SBATCH --gres=gpu:1
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=juenger@uni-mainz.de

# exit if anything goes wrong
set -e

# input/output (adjust according to your setup)
BAMFILE=$1
BAMINDEX=${BAMFILE}.bai
REFFILE=/project/pararch/dajuenge/variant_calling/data/crip_genome_v30.short.fasta
REFINDEX=${REFFILE}.fai
OUTDIR=output
JOBDIR=/localscratch/${SLURM_JOB_ID}
ARCH=gpu
MODEL=WGS

# add some information to the log file
echo "##################"
echo "#### Deep Variant for MOGON"
echo "#### JOB ID:" ${SLURM_JOB_ID}
echo "#### NODE:" $(hostname)
echo "#### MODEL:" ${MODEL}
echo "#### ARCH:" ${ARCH}
echo "#### BAM FILE:" ${BAMFILE}
echo "#### BAI FILE:" ${BAMINDEX}
echo "#### FASTA FILE:" ${REFFILE}
echo "#### FAI FILE:" ${REFINDEX}
echo "#### VCF FILE:" ${OUTDIR}/$(basename $BAMFILE).vcf
echo "#### GVCF FILE:" ${OUTDIR}/$(basename $BAMFILE).gvcf
echo "##################"

# load singularity module (adjust accodring to your environment)
module load tools/Singularity/3.5.2-Go-1.13.1

# create a job-local tmp directory for the container (never use a shared /tmp)
mkdir -p ${JOBDIR}/tmp

# copy input files to local scratch
cp $BAMFILE $JOBDIR/ &
cp $BAMINDEX $JOBDIR/ &
cp $REFFILE $JOBDIR/ &
cp $REFINDEX $JOBDIR/ &
wait

LOCAL_BAMFILE=${JOBDIR}/$(basename $BAMFILE)
LOCAL_REFFILE=${JOBDIR}/$(basename $REFFILE)
LOCAL_VCFFILE=${JOBDIR}/$(basename $BAMFILE).vcf
LOCAL_GVCFFILE=${JOBDIR}/$(basename $BAMFILE).gvcf

# execute deep variant inside the singularity container
# --nv flag enables GPU visibility inside the container
# -B mounts the local scratch and the job-local tmp directories inside the container
# environment.${ARCH}.sif represents the singularity image file
# for more information about the run_deepvariant script visit:
# https://github.com/google/deepvariant#how-to-run
singularity exec \
    --nv \
    -B ${JOBDIR} \
    -B ${JOBDIR}/tmp:/tmp \
    environment.${ARCH}.sif \
    run_deepvariant \
        --model_type=${MODEL} \
        --ref=${LOCAL_REFFILE} \
        --reads=${LOCAL_BAMFILE} \
        --output_vcf=${LOCAL_VCFFILE} \
        --output_gvcf=${LOCAL_GVCFFILE} \
        --num_shards=$(nproc)

# make sure the output directory exists
mkdir -p $OUTDIR

# copy results to output directory
cp $LOCAL_VCFFILE $OUTDIR/ &
cp $LOCAL_GVCFFILE $OUTDIR/ &
wait