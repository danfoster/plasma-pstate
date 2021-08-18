#!/bin/bash

export CPUFREQ=/sys/devices/system/cpu/cpu0/cpufreq

BASEDIR=$(dirname "$0")
# shellcheck disable=SC1091
source "${BASEDIR}"/cpu.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/intel.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/nvidia.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/lg_laptop.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/dell_laptop.sh
# shellcheck disable=SC1091
source "${BASEDIR}"/sysfs_available.sh

sensors_model=(
    # "kernel_version"
    "cpu_min_perf"
    "cpu_max_perf"
    "cpu_turbo"
    "gpu_min_freq"
    "gpu_max_freq"
    "gpu_min_limit"
    "gpu_max_limit"
    "gpu_boost_freq"
    "gpu_cur_freq"
    "cpu_governor"
    "energy_perf"
    "thermal_mode"
    "lg_battery_charge_limit"
    "lg_fan_mode"
    "lg_usb_charge"
    "powermizer"
    "intel_tcc_cur_state"
    "intel_tcc_max_state"
    "dell_fan_mode"
)

read_all () {
    json="{"
    read_sensors_model
    json="${json}}"
    echo "$json"
}

# Append a json key/value to the string variable 'json'.
#  e.g.
#   append_json '"foo":"bar"'
# 1: A json key/value
append_json() {
    if [ "${json#"${json%?}"}" = "{" ]; then
        json="${json}${1}"
    else
        json="${json},${1}"
    fi
}

# Helper macro to read sensor data and append it to the json string
# 1: Sensor name
append_macro() {
    _cmd="
        if check_${1}; then
            read_${1};
            append_json $(printf \"\\\\\"%s\\\\\":\\\\\"%s\\\\\"\" "${1}" \$\{"${1}"\});
        fi
    "
    # echo "$_cmd"
    eval "$_cmd"
}

read_sensors_model() {
    for sensor in "${sensors_model[@]}"
    do
        append_macro "$sensor"
    done
}

arg_to_sensor() {
    #shellcheck disable=SC2001
    _arg=$(echo "$1" | sed -e "s/-/_/g")
    _arg="${_arg:1}"
    _arg=$(printf '%s\n' "${sensors_model[@]}" | grep -P "^${_arg}\$")
    if [ -n "${_arg}" ]; then
        echo "${_arg}"
    else
        echo ""
    fi
}

read_some() {
    _all_sensors=$(printf '%s\n' "${sensors_model[@]}")

    json="{"

    for sensor in "${@}"
    do
        echo "${_all_sensors}" | grep -q -P "^${sensor}\$" || continue
        append_macro "${sensor}"
    done

    json="${json}}"
    echo "$json"
}

case $1 in

    "-read-all")
        read_all
        ;;

    "-read-available")
        read_available
        ;;

    "-read-some")
        read_some "${@:2}"
        ;;

    *)
        _sensor=$(arg_to_sensor "$1")
        if [ -n "${_sensor}" ]; then
            eval "set_${_sensor} ${2}"
            exit 0
        fi

        echo "Usage:"
        echo "1: set_prefs.sh [ -cpu-min-perf |"
        echo "                  -cpu-max-perf |"
        echo "                  -cpu-turbo |"
        echo "                  -gpu-min-freq |"
        echo "                  -gpu-max-freq |"
        echo "                  -gpu-boost-freq |"
        echo "                  -cpu-governor |"
        echo "                  -energy-perf |"
        echo "                  -thermal-mode |"
        echo "                  -lg-battery-charge-limit |"
        echo "                  -lg-fan-mode |"
        echo "                  -lg-usb-charge |"
        echo "                  -powermizer |"
        echo "                  -intel-tcc-cur-state |"
        echo "                  -dell-fan-mode ] value"
        echo "2: set_prefs.sh -read-all"
        echo "3: set_prefs.sh -read-available"
        echo "4: set_prefs.sh -read-some"
        exit 3
        ;;
esac
