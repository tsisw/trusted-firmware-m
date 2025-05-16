#-------------------------------------------------------------------------------
# Copyright (c) 2020-2024, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#-------------------------------------------------------------------------------

cmake_policy(SET CMP0076 NEW)

#========================= Platform region defs ===============================#

target_include_directories(platform_region_defs
    INTERFACE
        ${TSI_COMMON_DIR}/partition
        ${CMAKE_CURRENT_SOURCE_DIR}
)

#========================= Platform common defs ===============================#

# Specify the location of platform specific build dependencies.
target_sources(tfm_s
    PRIVATE
    ${TSI_COMMON_DIR}/device/source/startup_tsi.c
)
target_add_scatter_file(tfm_s
    $<$<C_COMPILER_ID:ARMClang>:${PLATFORM_DIR}/ext/common/armclang/tfm_common_s.sct>
    $<$<C_COMPILER_ID:GNU>:${PLATFORM_DIR}/ext/common/gcc/tfm_common_s.ld>
    $<$<C_COMPILER_ID:IAR>:${PLATFORM_DIR}/ext/common/iar/tfm_common_s.icf>
)

if(BL2)
    target_sources(bl2
        PRIVATE
	    ${TSI_COMMON_DIR}/device/source/startup_tsi.c
    )
    target_add_scatter_file(bl2
        $<$<C_COMPILER_ID:ARMClang>:${PLATFORM_DIR}/ext/common/armclang/tfm_common_bl2.sct>
        $<$<C_COMPILER_ID:GNU>:${PLATFORM_DIR}/ext/common/gcc/tfm_common_bl2.ld>
        $<$<C_COMPILER_ID:IAR>:${PLATFORM_DIR}/ext/common/iar/tfm_common_bl2.icf>
    )

    target_compile_options(bl2_scatter
        PUBLIC
            ${COMPILER_CMSE_FLAG}
    )
endif()

#========================= Device definition lib ===============================#

add_library(device_definition INTERFACE)
target_include_directories(device_definition
    INTERFACE
    	${TSI_COMMON_DIR}/device/include
	${TSI_COMMON_DIR}/native_drivers
	${TSI_COMMON_DIR}/partition
        ${PLATFORM_DIR}/ext/target/arm/drivers/flash/common
        ${PLATFORM_DIR}/ext/target/arm/drivers/usart/cmsdk
        ${PLATFORM_DIR}/ext/target/arm/drivers/usart/common
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpc_sie
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpu/armv8m
        ${PLATFORM_DIR}/ext/target/arm/drivers/counter/armv8m
        ${PLATFORM_DIR}/ext/target/arm/drivers/timer/armv8m
        ${PLATFORM_DIR}/ext/target/arm/drivers/tgu
        ${PLATFORM_DIR}/include
        ${ETHOS_DRIVER_PATH}/src
        ${ETHOS_DRIVER_PATH}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/device/config
        ${CMAKE_SOURCE_DIR}
)

#========================= Platform Secure ====================================#

target_include_directories(platform_s
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
	${TSI_COMMON_DIR}
	${TSI_COMMON_DIR}/cmsis_drivers
	${TSI_COMMON_DIR}/cmsis_drivers/config/secure
	${TSI_COMMON_DIR}/device
	${TSI_COMMON_DIR}/services/src
        ${PLATFORM_DIR}/ext/common
)

target_sources(platform_s
    PRIVATE
    	${TSI_COMMON_DIR}/cmsis_drivers/Driver_MPC.c
	${TSI_COMMON_DIR}/cmsis_drivers/Driver_TGU.c
	${TSI_COMMON_DIR}/cmsis_drivers/Driver_PPC.c
	${TSI_COMMON_DIR}/cmsis_drivers/Driver_USART.c
	${TSI_COMMON_DIR}/device/source/platform_s_device_definition.c
	${TSI_COMMON_DIR}/device/source/system_core_init.c
	${TSI_COMMON_DIR}/native_drivers/ppc_tsi_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/tgu/tgu_armv8_m_drv.c
	${TSI_COMMON_DIR}/tfm_peripherals_def.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/usart/cmsdk/uart_cmsdk_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpc_sie/mpc_sie_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/mpu/armv8m/mpu_armv8m_drv.c
        ${PLATFORM_DIR}/ext/target/arm/drivers/counter/armv8m/syscounter_armv8-m_cntrl_drv.c
        ${ETHOS_DRIVER_PATH}/src/ethosu_device_u55_u65.c
	$<$<OR:$<BOOL:${TFM_PARTITION_SLIH_TEST}>,$<BOOL:${TFM_PARTITION_FLIH_TEST}>>:${TSI_COMMON_DIR}/plat_test.c>
	$<$<BOOL:${TFM_PARTITION_PLATFORM}>:${TSI_COMMON_DIR}/services/src/tfm_platform_system.c>
)

target_sources(tfm_sprt
    PRIVATE
        # SLIH test Partition and FLIH test Partition access the timer as ARoT Partitions.
        # Put the driver to SPRT so that both SLIH and FLIH tests can access it.
        $<$<OR:$<BOOL:${TFM_PARTITION_SLIH_TEST}>,$<BOOL:${TFM_PARTITION_FLIH_TEST}>>:${PLATFORM_DIR}/ext/target/arm/drivers/timer/armv8m/systimer_armv8-m_drv.c>
)

# To configure S and NS timer in S side for FP interrupt test
target_compile_definitions(platform_s
    PUBLIC
        $<$<BOOL:${TEST_NS_FPU}>:TEST_NS_FPU>
        $<$<BOOL:${TEST_S_FPU}>:TEST_S_FPU>
)

target_compile_definitions(platform_s
    PUBLIC
        ETHOSU_ARCH=$<LOWER_CASE:${ETHOSU_ARCH}>
        ETHOS$<UPPER_CASE:${ETHOSU_ARCH}>
        ETHOSU_LOG_SEVERITY=${ETHOSU_LOG_SEVERITY}
)

target_compile_options(platform_s
    PUBLIC
        ${COMPILER_CP_FLAG}
        ${COMPILER_CMSE_FLAG}
)

target_link_options(platform_s
    PUBLIC
        ${LINKER_CP_OPTION}
)

target_link_libraries(platform_s
    PUBLIC
        device_definition
    PRIVATE
        tfm_sprt # For tfm_strnlen in attest HAL
)

#========================= Platform BL2 =======================================#

if(BL2)
    # boot_hal_bl2.c is compiled as part of 'bl2' target and not inside
    # 'platform_bl2' where it suppose to be. This is due to
    # platform_init/quit* apis symbol collision in bl1.
    target_sources(bl2
        PRIVATE
	    ${TSI_COMMON_DIR}/bl2/boot_hal_bl2.c
    )

    target_compile_options(bl2
        PUBLIC
            ${BL2_COMPILER_CP_FLAG}
            ${COMPILER_CMSE_FLAG}
    )

    target_link_options(bl2
        PUBLIC
            ${BL2_LINKER_CP_OPTION}
    )

    target_sources(platform_bl2
        PRIVATE
	    ${TSI_COMMON_DIR}/cmsis_drivers/Driver_USART.c
	    ${TSI_COMMON_DIR}/device/source/platform_s_device_definition.c
	    ${TSI_COMMON_DIR}/device/source/system_core_init.c
            ${PLATFORM_DIR}/ext/target/arm/drivers/flash/emulated/emulated_flash_drv.c
            ${PLATFORM_DIR}/ext/target/arm/drivers/usart/cmsdk/uart_cmsdk_drv.c
    )

    target_include_directories(platform_bl2
        PUBLIC
            device/include
	    ${TSI_COMMON_DIR}/device/include
        PRIVATE
	    ${TSI_COMMON_DIR}/device
	    ${TSI_COMMON_DIR}/services/src
            ${CMAKE_CURRENT_SOURCE_DIR}/device/config
	    ${TSI_COMMON_DIR}/cmsis_drivers/config/secure
	    ${TSI_COMMON_DIR}
    )

    target_compile_definitions(platform_bl2
        PUBLIC
            $<$<AND:$<BOOL:${CONFIG_TFM_BOOT_STORE_MEASUREMENTS}>,$<BOOL:${TFM_PARTITION_MEASURED_BOOT}>>:MEASURED_BOOT_API>
    )

    target_compile_options(platform_bl2
        PUBLIC
            ${BL2_COMPILER_CP_FLAG}
            ${COMPILER_CMSE_FLAG}
    )

    target_link_options(platform_bl2
        PUBLIC
            ${BL2_LINKER_CP_OPTION}
    )

    target_link_libraries(platform_bl2
        PRIVATE
            $<$<AND:$<BOOL:${CONFIG_TFM_BOOT_STORE_MEASUREMENTS}>,$<BOOL:${TFM_PARTITION_MEASURED_BOOT}>>:tfm_boot_status>
            device_definition
    )

endif()

#========================= tfm_spm ============================================#

target_sources(tfm_spm
    PRIVATE
        ${TSI_COMMON_DIR}/target_cfg.c
	${TSI_COMMON_DIR}/tfm_hal_platform.c
        ${PLATFORM_DIR}/ext/common/tfm_hal_platform_v8m.c
        ${PLATFORM_DIR}/ext/common/tfm_hal_isolation_v8m.c
        ${CMAKE_CURRENT_SOURCE_DIR}/dma_init.c
        $<$<OR:$<BOOL:${CONFIG_TFM_FLIH_API}>,$<BOOL:${CONFIG_TFM_SLIH_API}>>:${PLATFORM_DIR}/ext/common/tfm_interrupts.c>
)

# If this is not added to the tfm_s it will not correctly override the weak
# default handlers declared in assemebly, and will instead be discarded as they
# are not in use.
target_sources(tfm_s
    PRIVATE
        ${PLATFORM_DIR}/ext/common/mpc_ppc_faults.c
)

#========================= platform_region_defs ===============================#
target_compile_definitions(platform_region_defs
    INTERFACE
        S_DATA_OVERALL_SIZE=${S_DATA_OVERALL_SIZE}
        FLASH_S_PARTITION_SIZE=${FLASH_S_PARTITION_SIZE}
        FLASH_NS_PARTITION_SIZE=${FLASH_NS_PARTITION_SIZE}
        PROVISIONING_CODE_PADDED_SIZE=${PROVISIONING_CODE_PADDED_SIZE}
        PROVISIONING_VALUES_PADDED_SIZE=${PROVISIONING_VALUES_PADDED_SIZE}
        PROVISIONING_DATA_PADDED_SIZE=${PROVISIONING_DATA_PADDED_SIZE}
        $<$<BOOL:${MCUBOOT_BUILTIN_KEY}>:MCUBOOT_BUILTIN_KEY>
)

if(NOT PLATFORM_DEFAULT_PROVISIONING)
    add_subdirectory(${PLATFORM_DIR}/ext/common/provisioning_bundle provisioning)
endif()

#========================= Files for building NS side platform ================#
target_compile_definitions(tfm_config
    INTERFACE
        S_DATA_OVERALL_SIZE=${S_DATA_OVERALL_SIZE}
        FLASH_S_PARTITION_SIZE=${FLASH_S_PARTITION_SIZE}
        FLASH_NS_PARTITION_SIZE=${FLASH_NS_PARTITION_SIZE}
        PROVISIONING_CODE_PADDED_SIZE=${PROVISIONING_CODE_PADDED_SIZE}
        PROVISIONING_VALUES_PADDED_SIZE=${PROVISIONING_VALUES_PADDED_SIZE}
        PROVISIONING_DATA_PADDED_SIZE=${PROVISIONING_DATA_PADDED_SIZE}
)

install(FILES       ${TSI_COMMON_DIR}/cmsis_drivers/Driver_USART.c
		    ${TSI_COMMON_DIR}/cmsis_drivers/config/non_secure/cmsis_driver_config.h
		    ${TSI_COMMON_DIR}/cmsis_drivers/config/non_secure/RTE_Device.h
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common/cmsis_drivers)

install(DIRECTORY   ${TSI_COMMON_DIR}/device
		    ${TSI_COMMON_DIR}/native_drivers
		    ${TSI_COMMON_DIR}/cmsis_drivers
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common)

install(DIRECTORY   ${PLATFORM_DIR}/ext/target/arm/drivers
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/ext/target/arm)

install(FILES       ${PLATFORM_DIR}/ext/driver/Driver_USART.h
                    ${PLATFORM_DIR}/ext/driver/Driver_Common.h
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/ext/driver)

install(FILES       ${TSI_COMMON_DIR}/target_cfg.h
		    ${TSI_COMMON_DIR}/tfm_peripherals_def.h
                    ${PLATFORM_DIR}/include/tfm_plat_defs.h
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common/include)

install(FILES       ${PLATFORM_DIR}/ext/common/common_target_cfg.h
                    ${PLATFORM_DIR}/ext/common/test_interrupt.h
                    ${PLATFORM_DIR}/ext/common/test_interrupt.c
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/ext/common)

install(DIRECTORY   ${TSI_COMMON_DIR}/partition
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common)

install(FILES       ${TSI_COMMON_DIR}/cpuarch.cmake
		    ${TSI_COMMON_DIR}/config.cmake
		    ${TSI_COMMON_DIR}/target_cfg.h
		    ${TSI_COMMON_DIR}/check_config.cmake
		    ${TSI_COMMON_DIR}/ns/common.cmake
        DESTINATION ${INSTALL_PLATFORM_NS_DIR}/common)

install(DIRECTORY   ${TSI_COMMON_DIR}/tests
        DESTINATION ${INSTALL_PLATFORM_NS_DIR})

if(DEFAULT_NS_SCATTER)
    # Install linker scripts
    install(FILES       ${PLATFORM_DIR}/ext/common/armclang/tfm_common_ns.sct
                        ${PLATFORM_DIR}/ext/common/gcc/tfm_common_ns.ld
                        ${PLATFORM_DIR}/ext/common/iar/tfm_common_ns.icf
            DESTINATION ${INSTALL_PLATFORM_NS_DIR}/linker_scripts)
endif()
