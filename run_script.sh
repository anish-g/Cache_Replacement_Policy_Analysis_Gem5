#!/bin/bash

declare -a ALGORITHMS=("RandomRP" "LRURP" "MRURP" "LFURP" "FIFORP" "NRURP" "TreePLRURP" "BIPRP" "SecondChanceRP" "RRIPRP" "BRRIPRP")
declare -a BENCHMARKS=("queens" "sha" "BFS" "blocked-matmul")


current_time=$(date "+%Y-%m-%d-%H-%M-%S")
sim_name="sim-out-${current_time}"
output_foldername="m5out/${sim_name}"
summary_file="${output_foldername}/output.txt"
csv_filepath="${output_foldername}/output.csv"

mkdir -p $output_foldername
echo -e "RESULTS FOR SIMULATION ===> ${sim_name} <===" > "${summary_file}"
echo -e "************************************************************\n\n" >> "${summary_file}"

counter=0

echo -e "\n****** SIMULATION STARTED ******\\n"

for algo in ${ALGORITHMS[@]}
do
    
    for bm in ${BENCHMARKS[@]}
    do
        # Changing policy in the Cache.py 
        sed -i ":a;N;\$!ba;s|replacement_policy = Param.BaseReplacementPolicy(\n\s*[^,]*\(), \"Replacement policy\"\)|replacement_policy = Param.BaseReplacementPolicy(\n\t\t$algo(\1|g" src/mem/cache/Cache.py

        ((counter++))

        # make output directories
        result_dest="${output_foldername}/$algo/$bm"
        mkdir -p $result_dest

        echo -e "       Experiment: $counter       "
        echo -e "****** Algorithm: $algo ******"
        echo -e "------ Benchmark: $bm ------\\n"

        # build/X86/gem5.opt configs/learning_gem5/part1/three_level_cache.py configs/learning_gem5/part1/benchmarks/BFS
        build/X86/gem5.opt -d $result_dest configs/learning_gem5/part1/three_level_cache.py configs/learning_gem5/part1/benchmarks/$bm

        echo -e "\nStoring simulation results in:\n${result_dest}"

        echo -e "\nTabulating result summary: ${summary_file}"
        echo -e "============================================================" >> "${summary_file}"
        echo -e "Experiment: $counter\tAlgorithm: $algo\tBenchmark: $bm" >> "${summary_file}"
        echo -e "------------------------------------------------------------" >> "${summary_file}"
        cat $result_dest/stats.txt | grep hostSeconds >> "${summary_file}"
		cat $result_dest/stats.txt | grep hostTickRate >> "${summary_file}"
        cat $result_dest/stats.txt | grep hostMemory >> "${summary_file}"
        cat $result_dest/stats.txt | grep simInsts >> "${summary_file}"
        cat $result_dest/stats.txt | grep hostInstRate >> "${summary_file}"
        cat $result_dest/stats.txt | grep hostOpRate >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.dcache.overallHits::total  >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.dcache.overallMisses::total >> "${summary_file}"
		cat $result_dest/stats.txt | grep system.cpu.dcache.overallAccesses::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.dcache.overallAvgMissLatency::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.dcache.tags.tagsInUse  >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.dcache.tags.avgOccs::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.icache.overallHits::total >> "${summary_file}"
		cat $result_dest/stats.txt | grep system.cpu.icache.overallMisses::total >> "${summary_file}"
		cat $result_dest/stats.txt | grep system.cpu.icache.overallAccesses::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.icache.overallAvgMissLatency::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.icache.tags.tagsInUse >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.cpu.icache.tags.avgOccs::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l2cache.overallAvgMissLatency::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l3cache.overallAvgMissLatency::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l2cache.tags.tagsInUse >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l3cache.tags.tagsInUse >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l3cache.tags.tagsInUse >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l2cache.tags.avgOccs::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.l3cache.tags.avgOccs::total >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.mem_ctrl.dram.rank0.totalEnergy >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.mem_ctrl.dram.rank0.averagePower >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.mem_ctrl.readReqs >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.mem_ctrl.writeReqs >> "${summary_file}"
        cat $result_dest/stats.txt | grep system.mem_ctrl.readBursts >> "${summary_file}"
        echo -e "============================================================\n\n" >> "${summary_file}"

        echo ""

    done
done

echo -e "Compiling the relevant information in CSV: ${csv_filepath}"
python configs/learning_gem5/part1/compile_results.py --txt ${summary_file} --csv ${csv_filepath}

echo -e "\n****** SIMULATION COMPLETED ******\\n"