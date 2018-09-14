Pool1.protocol
	fastq-mcf (to remove adapter)
	my_stampy_pipeline_PE
		stampy.py
		sam2art.pl
		sam_statistics.pl
		genes_statistics.R
	my_samtools_SNP_pipeline
		samtools view
		samtools sort
		samtools index
		samtools mpileup -uf $reference $prefix.bam | bcftools view -bvcg
		bcftools view $prefix.raw.bcf | vcfutils.pl varFilter -d $mindepth > $prefix.flt.vcf
	mutation_table.py
		-f dict.txt -a /data3/reference_sequences/Pseudomonas_aeruginosa_PA14_annotation_with_ncRNAs_07_2011_12genes.tab -o DNA-Pool1.tab
		- dict.txt: prefix of ".flt.vcf" (the file some_line+".flt.vcf")
		- .flt.vcf: generated above		
		- Pseudomonas_aeruginosa_PA14_annotation_with_ncRNAs_07_2011_12genes.tab: to be deprecated
	Snp2Amino.py
		-f DNA-Pool1.tab -g /data3/reference_sequences/Pseudomonas_aeruginosa_PA14_ncRNA.gbk -o DNA_Pool1_final.tab
		- DNA-Pool1.tab: created by mutation_table.py

== my_stampy_pipeline_PE ==
	
#!/usr/bin/csh -f
#align illumina reads using stampy and art-file for visualization

set prefix  = $1	# used to name the different output files
set infile1 = $2	# name of input fastq file containing the left end reads 
set infile2 = $3	# name of input fastq file containing the right end reads
set reffiles = $4	# path and prefix of reference files
set annofile = $5	# path to annotation file
set Rannofile = $6	# path to annotation file

set indexref  = $reffiles
set hashref   = $reffiles
set bwaopt    = "-q10 $reffiles"
set annotation = $annofile
set Rannotation = $Rannofile
#set annotation = "/data3/reference_sequences/Pseudomonas_aeruginosa_PA14_annotation_pseudomonas_com_07_2011.tab"

#echo  "starting stampy"
/usr/local/stampy.py --bwaoptions="$bwaopt" -g $indexref -h $hashref -M $infile1 $infile2 > $prefix.sam #2> $prefix.report
#/usr/local/stampy.py --solexa --bwaoptions="$bwaopt" -g $indexref -h $hashref -M $infile1 $infile2 > $prefix.sam #2> $prefix.report

#echo  "writing art file"
sam2art.pl -s 2 -p -4 $prefix.sam > $prefix.art

#echo  "writing sin file"
sam2art.pl -s 2 -l -p -4 $prefix.sam > $prefix.sin

#echo  "writing flat pileup file"
sam2art.pl -f -s 2 -p $prefix.sam > $prefix.flatcount

#echo  "making gene counts"
art2genecount.pl -b -a $prefix.sin -t tab -r $annotation > $prefix.rpg

#echo  "writing statistics"
sam_statistics.pl -r -p $prefix.sam > $prefix.stats
genes_statistics.R $prefix.rpg $Rannotation $prefix.stats $prefix

== my_samtools_SNP_pipeline ==

#!/usr/bin/csh -f
#align illumina reads using stampy and art-file for visualization

set prefix  	= $1	# used to name the different output files
set reference	= $2	# path and prefix of reference file
set mindepth	= $3	# minimum read depth for filtering variants

### Converting to BAM ###
samtools view -bS $prefix.sam > $prefix.bam

### Sorting BAM ###
samtools sort $prefix.bam $prefix

### Indexing BAM ###
samtools index $prefix.bam

### Variant calling ###
samtools mpileup -uf $reference $prefix.bam | bcftools view -bvcg - > $prefix.raw.bcf

### Variant filtering ###
bcftools view $prefix.raw.bcf | vcfutils.pl varFilter -d $mindepth > $prefix.flt.vcf