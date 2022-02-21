#!/usr/bin/env bash

############################################################################
# Prints important log messages in cyan color; pink messages are generated
# by the local running deployment shell script, while cyan messages
# are generated by what is usually run inside of the Kubernetes pod.
# Arguments:
#   Info message
############################################################################
function emphasize {
  printf "\e[38;5;81m--- $1 ---\e[0m\n"
}

emphasize "Creating Summary Directory"
if [[ -d summary ]]
then
    rm -rf summary
fi
mkdir summary

emphasize "Rendering K6 Files"
python3 -m perf_test.scripts.renderer -r render -t $TEMPLATE_DIR -s summary -c $CONFIG_FILE

emphasize "Creating Results Directory"
if [[ -d results ]]
then
    rm -rf results
fi
mkdir results

emphasize "Starting K6 Tests"
for TEST in render/*.js; do
  emphasize "Beginning K6 test: ${TEST}"
  RESULT_FILE=results/`basename "${TEST%.*}".txt`
  SUMMARY_FILE_JSON=summary/`basename "${TEST%.*}".json`
  # Write StartTime to File
  date >> $RESULT_FILE
  # Then, run the test itself, dumping the important information into the result file
  k6 run $TEST --summary-export=$SUMMARY_FILE_JSON >> $RESULT_FILE
  # Write EndTime to File
  date >> $RESULT_FILE;

  emphasize "Intermediate test results for: ${TEST}"
  cat $RESULT_FILE

#   emphasize "Generating intermediate Markdown for K6 tests..."
#   python3 -m src.k6.scraper -r results -s summary -p persistent-results -c $CONFIG_FILE -k configs/kingdom.dict

  if [ $? -eq 137 ]; then
    emphasize "ERROR: TEST $TEST WAS OOMKILLED; IT WILL NOT PRODUCE ANY RESULTS."
    rm $RESULT_FILE
  fi

  TEST_NO=$((TEST_NO+1))
  emphasize "Waiting 5s before next test"
  sleep 5
done

# emphasize "Generating final Markdown for K6 tests..."
# python3 -m src.k6.scraper -r results -s summary -p persistent-results -c $CONFIG_FILE -k configs/kingdom.dict
# emphasize "K6 TESTS ARE COMPLETE. Use the following command to copy to your CWD."
# echo "kubectl cp ${POD_NAME}:output.md ./output.md && kubectl cp ${POD_NAME}:summary.json ./summary.json"
