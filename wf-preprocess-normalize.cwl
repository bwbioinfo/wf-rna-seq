cwlVersion: v1.0
class: Workflow
label: Preprocessing Workflow

requirements:
  - class: InlineJavascriptRequirement

inputs:
  reads:
    type: File[]
    inputBinding:
      position: 1

outputs:
  normalized_reads:
    type: File
    outputSource: bbnorm.normalized_reads

steps:
  1-format_conversion:
    run: ./cwl-tools/reformat-tool.cwl
    in:
      in_reads: reads
    out:
      reformatted_reads: intermediate/interleaved.fastq

  2-adapter_trimming:
    run: ./cwl-tools/bbduk-tool.cwl
    in:
      in_reads: 1-format_conversion/reformatted_reads
    out:
      filtered_reads: intermediate/cleaned.fastq

  3-contaminant_filtering:
    run: ./cwl-tools/bbduk-tool.cwl
    in:
      in_reads: 2-adapter_trimming/filtered_reads
    out:
      filtered_reads: intermediate/decontaminated.fastq
      contaminants: intermediate/contaminants.fastq
      stats: intermediate/contaminant_stats.txt

  4-split_decontaminated_reads:
    run: ./cwl-tools/reformat-tool.cwl
    in:
      in_reads: contaminant_filtering/filtered_reads
    out:
      decontaminated_reads: intermediate/decontaminated_R#.fastq
      singletons: intermediate/decontaminated_singletons.fastq
    when: $(inputs.reads.length > 1)

  5-normalize_reads:
    run: ./cwl-tools/bbnorm-tool.cwl
    in:
      in_reads: contaminant_filtering/filtered_reads
    out:
      normalized_reads: output/normalized.fastq

  6-split_normalized_reads:
    run: ./cwl-tools/reformat-tool.cwl
    in:
      in_reads: normalize_reads/normalized_reads
    out:
      normalized_reads: output/normalized_R#.fastq
      singletons: output/normalized_singletons.fastq
    when: $(inputs.reads.length > 1)
