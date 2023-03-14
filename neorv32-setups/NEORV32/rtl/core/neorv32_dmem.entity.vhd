-- #################################################################################################
-- # << NEORV32 - Processor-internal data memory (DMEM) >>                                         #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neorv32_dmem is
  generic (
    DMEM_BASE : std_ulogic_vector(31 downto 0); -- memory base address
    DMEM_SIZE : natural -- processor-internal instruction memory size in bytes
  );
  port (
    s_axi_aclk   : in  std_logic;        
    s_axi_aresetn : in  std_logic;
    -- Write Address Channel --
    s_axi_awaddr  : in std_logic_vector(31 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out  std_logic;
    -- Write Data Channel --
    s_axi_wdata   : in std_logic_vector(31 downto 0);
    s_axi_wstrb   : in std_logic_vector(3 downto 0);
    s_axi_wvalid  : in std_logic;
    s_axi_wready  : out  std_logic;
    -- Read Address Channel --
    s_axi_araddr  : in std_logic_vector(31 downto 0);
    s_axi_arprot  : in std_logic_vector(2 downto 0);
    s_axi_arvalid : in std_logic;
    s_axi_arready : out  std_logic;
    -- Read Data Channel --
    s_axi_rdata   : out  std_logic_vector(31 downto 0);
    s_axi_rresp   : out  std_logic_vector(1 downto 0);
    s_axi_rvalid  : out  std_logic;
    s_axi_rready  : in std_logic;
    -- Write Response Channel --
    s_axi_bresp   : out  std_logic_vector(1 downto 0);
    s_axi_bvalid  : out  std_logic;
    s_axi_bready  : in std_logic;
    
    clk_i  : in  std_ulogic; -- global clock line
    rden_i : in  std_ulogic; -- read enable
    wren_i : in  std_ulogic; -- write enable
    ben_i  : in  std_ulogic_vector(03 downto 0); -- byte write enable
    addr_i : in  std_ulogic_vector(31 downto 0); -- address
    data_i : in  std_ulogic_vector(31 downto 0); -- data in
    data_o : out std_ulogic_vector(31 downto 0); -- data out
    ack_o  : out std_ulogic -- transfer acknowledge
  );
end neorv32_dmem;
