#-------------------------------------------------------------------------------
# Copyright (c) 2022-2023, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#-------------------------------------------------------------------------------

include(${TSI_COMMON_DIR}/config.cmake)

set(PLATFORM_SVC_HANDLERS             ON    CACHE BOOL    "Platform specific SVC handlers")
set(PROVISIONING_CODE_PADDED_SIZE       "0x2000"  CACHE STRING    "")
set(PROVISIONING_VALUES_PADDED_SIZE     "0x400"   CACHE STRING    "")
set(PROVISIONING_DATA_PADDED_SIZE       "0x400"   CACHE STRING    "")

if(BL1)
    set(PLATFORM_DEFAULT_BL1              ON               CACHE STRING   "Whether to use default BL1 or platform-specific one")
endif()
