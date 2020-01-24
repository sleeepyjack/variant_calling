#!/bin/sh

#######################
#    Prerequisites    #
#######################

# exit if anything goes wrong
set -e

# target install directory inside container
INSTALL_DIR=/opt
mkdir -p $INSTALL_DIR

# download/cache directory
TEMP_DIR=/tmp/container_bootstrap_cache
mkdir -p $TEMP_DIR

# will be prepended to the container's environment
PATH_EXTENSION=/opt/bin:/opt/deepvariant/bin
LD_LIBRARY_PATH_EXTENSION=''

# specify number of logical cores to speed-up compilation
NUM_CORES=4
#NUM_CORES=$(grep -c ^processor /proc/cpuinfo)

# set locale
echo "export LC_ALL=C" >> $SINGULARITY_ENVIRONMENT

# update packages
apt-get update
apt-get -y upgrade

####### INSTALL #######
#    Base Packages    #
#######################

apt-get install -y vim htop wget

####### INSTALL #######
#        Java         #
#######################

JAVA_VERSION=11

apt-get install -y software-properties-common python-software-properties
add-apt-repository ppa:openjdk-r/ppa
apt-get update
apt-get install -y openjdk-$JAVA_VERSION-jre

####### INSTALL #######
#         BWA         #
#######################

# set version and target directory
BWA_VERSION=0.7.17
BWA_DIR=$INSTALL_DIR/bwa

# download and install
cd $TEMP_DIR
# TODO strip characters at the end of version
wget -c https://github.com/lh3/bwa/releases/download/v$BWA_VERSION/bwa-$BWA_VERSION.tar.bz2
tar -xvf bwa-$BWA_VERSION.tar.bz2
mv bwa-$BWA_VERSION $BWA_DIR
cd $BWA_DIR
make -j $NUM_CORES

# add to PATH
PATH_EXTENSION=$PATH_EXTENSION:$BWA_DIR

####### INSTALL #######
#     SRA Toolkit     #
#######################

SRA_TOOLKIT_VERSION=2.10.2
SRA_TOOLKIT_DIR=$INSTALL_DIR/sratoolkit

cd $TEMP_DIR
wget -c http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/$SRA_TOOLKIT_VERSION/sratoolkit.$SRA_TOOLKIT_VERSION-ubuntu64.tar.gz
tar -xvzf sratoolkit.$SRA_TOOLKIT_VERSION-ubuntu64.tar.gz
mv sratoolkit.$SRA_TOOLKIT_VERSION-ubuntu64 $SRA_TOOLKIT_DIR

PATH_EXTENSION=$PATH_EXTENSION:$SRA_TOOLKIT_DIR/bin

####### INSTALL #######
# Parallel FASTQ Dump #
#######################

PARALLEL_FASTQ_DUMP_VERSION=0.6.6
PARALLEL_FASTQ_DUMP_DIR=$INSTALL_DIR/parallel-fastq-dump

cd $TEMP_DIR
wget -c https://github.com/rvalieris/parallel-fastq-dump/archive/$PARALLEL_FASTQ_DUMP_VERSION.tar.gz
tar -xvzf $PARALLEL_FASTQ_DUMP_VERSION.tar.gz
mv parallel-fastq-dump-$PARALLEL_FASTQ_DUMP_VERSION $PARALLEL_FASTQ_DUMP_DIR

PATH_EXTENSION=$PATH_EXTENSION:$PARALLEL_FASTQ_DUMP_DIR

####### INSTALL #######
#       FastQC        #
#######################

FASTQC_VERSION=0.11.9
FASTQC_DIR=$INSTALL_DIR/fastqc

cd $TEMP_DIR
wget -c https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v$FASTQC_VERSION.zip
unzip -u fastqc_v$FASTQC_VERSION.zip
mv FastQC $FASTQC_DIR
chmod +x $FASTQC_DIR/fastqc

PATH_EXTENSION=$PATH_EXTENSION:$FASTQC_DIR

####### INSTALL #######
#        BBMap        #
#######################

BBMAP_VERSION=35.85
BBMAP_DIR=$INSTALL_DIR/bbmap

cd $TEMP_DIR
wget -c https://github.com/BioInfoTools/BBMap/releases/download/v$BBMAP_VERSION/BBMap_$BBMAP_VERSION.tar.gz
tar -xvzf BBMap_$BBMAP_VERSION.tar.gz
mv bbmap $BBMAP_DIR

PATH_EXTENSION=$PATH_EXTENSION:$BBMAP_DIR

####### INSTALL #######
#        GATK         #
#######################

GATK_VERSION=4.1.4.1
GATK_DIR=$INSTALL_DIR/gatk

cd $TEMP_DIR
wget -c https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip
unzip -u gatk-$GATK_VERSION.zip
mv gatk-$GATK_VERSION $GATK_DIR

PATH_EXTENSION=$PATH_EXTENSION:$GATK_DIR

####### INSTALL #######
#       Picard        #
#######################

PICARD_VERSION=2.21.7
PICARD_DIR=$INSTALL_DIR/picard

cd $TEMP_DIR
wget https://github.com/broadinstitute/picard/releases/download/$PICARD_VERSION/picard.jar
mkdir $PICARD_DIR
mv picard.jar $PICARD_DIR

PATH_EXTENSION=$PATH_EXTENSION:$PICARD_DIR

####### INSTALL #######
#      SAMTools       #
#######################

SAMTOOLS_VERSION=1.10
SAMTOOLS_DIR=$INSTALL_DIR/samtools

cd $TEMP_DIR
apt-get install -y libncurses5-dev libncursesw5-dev
wget -c https://github.com/samtools/samtools/releases/download/$SAMTOOLS_VERSION/samtools-$SAMTOOLS_VERSION.tar.bz2
tar -xvf samtools-$SAMTOOLS_VERSION.tar.bz2
mv samtools-$SAMTOOLS_VERSION $SAMTOOLS_DIR
cd $SAMTOOLS_DIR
make -j $NUM_CORES

PATH_EXTENSION=$PATH_EXTENSION:$SAMTOOLS_DIR

####### INSTALL #######
#      BAMTools       #
#######################

BAMTOOLS_VERSION=2.5.1
BAMTOOLS_DIR=$INSTALL_DIR/bamtools

cd $TEMP_DIR
apt-get install -y cmake libjsoncpp-dev
wget -c https://github.com/pezmaster31/bamtools/archive/v$BAMTOOLS_VERSION.tar.gz
tar -xvzf v$BAMTOOLS_VERSION.tar.gz
cd bamtools-$BAMTOOLS_VERSION
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$BAMTOOLS_DIR ..
make -j $NUM_CORES
make install
cd ../..
rm -rf bamtools-$BAMTOOLS_VERSION

PATH_EXTENSION=$PATH_EXTENSION:$BAMTOOLS_DIR/bin
LD_LIBRARY_PATH_EXTENSION=$LD_LIBRARY_PATH_EXTENSION:$BAMTOOLS_DIR/lib

# TODO multiqc

# extend container environment
echo "export PATH=$PATH_EXTENSION:$PATH" >> $SINGULARITY_ENVIRONMENT
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH_EXTENSION:$LD_LIBRARY_PATH" >> $SINGULARITY_ENVIRONMENT