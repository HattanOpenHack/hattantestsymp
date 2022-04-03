#!/bin/bash

# include helpers
source _helpers.sh

usage() {
  _information "Usage: ${0} [terraform or bicep]"
  exit 1
}

print() {
  _success "${1}"

  echo -e "--------------------------------------------------------------------------------\n[$(date)] : ${1}" | tee -a test.out
}

terraform() {
  TEST_FILE_NAME=${1:-}

  # cd into the terraform directory
  cd ../../IAC/Terraform/

  # cleanup any existing state
  rm -rf ./terraform/**/.terraform
  rm -rf ./terraform/**/*.tfplan
  rm -rf ./terraform/**/*.tfstate
  rm -rf ./terraform/backend.tfvars
  rm -rf ./terraform/**/terraform.tfstate.backup

  # cd to the test directory
  cd ./test

  CWD=$(pwd)

  if [ -z "${TEST_FILE_NAME}" ]; then
      # find all tests
      TEST_FILE_NAMES=`find ${CWD}/**/*.go`

      # run all tests
      for TEST_FILE_NAME in ${TEST_FILE_NAMES}; do
        print "Running tests for '${TEST_FILE_NAME}'"

        go test -v -timeout 6000s ${TEST_FILE_NAME} | tee -a test.out
      done
  else
      # find the go file based on the filename
      TEST_FILE=`find ${CWD}/**/${TEST_FILE_NAME}`

      print "Running tests for '${TEST_FILE}'"

      # run a specific test
      go test -v -timeout 6000s ${TEST_FILE} | tee -a test.out
  fi
}

bicep() {

  arm_ttk() {
    # run arm-ttk tests
    pushd ./arm-ttk

      az bicep build --file ../../bicep/01_sql/02_deployment/main.bicep

      pwsh -Command \
      "
        Import-Module ./arm-ttk.psd1
        Test-AzTemplate -TemplatePath ../../bicep/01_sql/02_deployment/main.json
        Remove-Item -Force -Path ../../bicep/01_sql/02_deployment/main.json
      "

    # return to the previous directory
    popd
  }

  pester() {
    # run pester tests
    pushd ./pester

      # if the test file is not specified, run for all files
      if [ -z "${1}" ]; then
        pwsh -Command "Invoke-Pester -OutputFile Test.xml -OutputFormat NUnitXML"
      else
        TEST_FILE=`find ${1}`

        if [ ! -z "${TEST_FILE}" ]; then
          pwsh -Command "Invoke-Pester -OutputFile Test.xml -OutputFormat NUnitXML ${TEST_FILE}"
        fi
      fi

    # return to the previous directory
    popd
  }

  shellspec() {
    # run spec tests
    pushd ./spec

    shellspec -f d

    # return to the previous directory
    popd
  }

  # cd to the tests directory
  cd ../../IAC/Bicep/test

}

# if no arguments are passed, show usage
if [ -z "$1" ]; then
  echo "No arguments passed"
  usage
fi

# parse the arguments
case ${1} in
  terraform)
    shift
    terraform $@
    ;;
  bicep)
    shift
    bicep $@
    ;;
  *)
    echo "Invalid argument: ${1}"
    usage
    ;;
esac