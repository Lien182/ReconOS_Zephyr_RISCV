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

library neorv32;
use neorv32.neorv32_package.all;

architecture neorv32_dmem_rtl of neorv32_dmem is

  -- IO space: module base address --
  constant hi_abb_c : natural := 31; -- high address boundary bit
  constant lo_abb_c : natural := index_size_f(DMEM_SIZE); -- low address boundary bit

  -- local signals --
  signal acc_en : std_ulogic;
  signal rdata  : std_ulogic_vector(31 downto 0);
  signal rden   : std_ulogic;
  signal addr   : std_ulogic_vector(index_size_f(DMEM_SIZE/4)-1 downto 0);

  -- -------------------------------------------------------------------------------------------------------------- --
  -- The memory (RAM) is built from 4 individual byte-wide memories b0..b3, since some synthesis tools have         --
  -- problems with 32-bit memories that provide dedicated byte-enable signals AND/OR with multi-dimensional arrays. --
  -- -------------------------------------------------------------------------------------------------------------- --

  -- RAM - not initialized at all --
  signal mem_ram_b0 : mem8_t(0 to DMEM_SIZE/4-1);
  signal mem_ram_b1 : mem8_t(0 to DMEM_SIZE/4-1);
  signal mem_ram_b2 : mem8_t(0 to DMEM_SIZE/4-1);
  signal mem_ram_b3 : mem8_t(0 to DMEM_SIZE/4-1);

  -- read data --
  signal mem_ram_b0_rd, mem_ram_b1_rd, mem_ram_b2_rd, mem_ram_b3_rd : std_ulogic_vector(7 downto 0);


  -- AXI4LITE signals --
	signal axi_awaddr	: std_logic_vector(31 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(31 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(31 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;
  

  -- AXI4LITE memory access signals --
  signal axi_read_addr : std_ulogic_vector(index_size_f(DMEM_SIZE/4)-1 downto 0);
  signal axi_write_addr : std_ulogic_vector(index_size_f(DMEM_SIZE/4)-1 downto 0);
  signal s_wren : std_logic;
  signal s_ren : std_logic;
  signal reg_data_out : std_ulogic_vector(31 downto 0);

begin

  -- Sanity Checks --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  assert false report "NEORV32 PROCESSOR CONFIG NOTE: Using DEFAULT platform-agnostic DMEM." severity note;
  assert false report "NEORV32 PROCESSOR CONFIG NOTE: Implementing processor-internal DMEM (RAM, " & natural'image(DMEM_SIZE) & " bytes)." severity note;

  -- I/O Connections assignments

  	s_axi_awready	<= axi_awready;
	s_axi_wready	<= axi_wready;
	s_axi_bresp	<= axi_bresp;
	s_axi_bvalid	<= axi_bvalid;
	s_axi_arready	<= axi_arready;
	s_axi_rdata	<= axi_rdata;
	s_axi_rresp	<= axi_rresp;
	s_axi_rvalid	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one s_axi_aclk clock cycle when both
	-- s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
	-- de-asserted when reset is low.


  -- CPU Access Control -------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  acc_en <= '1' when (addr_i(hi_abb_c downto lo_abb_c) = DMEM_BASE(hi_abb_c downto lo_abb_c)) else '0';
  addr   <= addr_i(index_size_f(DMEM_SIZE/4)+1 downto 2); -- word aligned
   
  -- AXI4LITE Access Control -------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  axi_read_addr <= std_ulogic_vector(axi_araddr(index_size_f(DMEM_SIZE/4)+1 downto 2)); -- word aligned
  axi_write_addr <= std_ulogic_vector(axi_awaddr(index_size_f(DMEM_SIZE/4)+1 downto 2)); -- word aligned

  -- Memory Access --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  mem_access: process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- this RAM style should not require "no_rw_check" attributes as the read-after-write behavior
      -- is intended to be defined implicitly via the if-WRITE-else-READ construct
      if (acc_en = '1') then -- reduce switching activity when not accessed
        if (wren_i = '1') and (ben_i(0) = '1') then -- byte 0
          mem_ram_b0(to_integer(unsigned(addr))) <= data_i(07 downto 00);
        else
          mem_ram_b0_rd <= mem_ram_b0(to_integer(unsigned(addr)));
        end if;
        if (wren_i = '1') and (ben_i(1) = '1') then -- byte 1
          mem_ram_b1(to_integer(unsigned(addr))) <= data_i(15 downto 08);
        else
          mem_ram_b1_rd <= mem_ram_b1(to_integer(unsigned(addr)));
        end if;
        if (wren_i = '1') and (ben_i(2) = '1') then -- byte 2
          mem_ram_b2(to_integer(unsigned(addr))) <= data_i(23 downto 16);
        else
          mem_ram_b2_rd <= mem_ram_b2(to_integer(unsigned(addr)));
        end if;
        if (wren_i = '1') and (ben_i(3) = '1') then -- byte 3
          mem_ram_b3(to_integer(unsigned(addr))) <= data_i(31 downto 24);
        else
          mem_ram_b3_rd <= mem_ram_b3(to_integer(unsigned(addr)));
        end if;
      end if;
    end if;
  end process mem_access;


  -- Bus Feedback ---------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  bus_feedback: process(clk_i)
  begin
    if rising_edge(clk_i) then
      rden  <= acc_en and rden_i;
      ack_o <= acc_en and (rden_i or wren_i);
    end if;
  end process bus_feedback;

  -- pack --
  rdata <= mem_ram_b3_rd & mem_ram_b2_rd & mem_ram_b1_rd & mem_ram_b0_rd;

  -- output gate --
  data_o <= rdata when (rden = '1') else (others => '0');

  -- AXI4LITE Memory Access --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------

  ready_process: process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_awready <= '0';
	    else
	      if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	        axi_awready <= '1';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process ready_process;

  -- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- s_axi_awvalid and s_axi_wvalid are valid. 

  valid_process: process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1') then
	        -- Write Address latching
	        axi_awaddr <= s_axi_awaddr;
	      end if;
	    end if;
	  end if;                   
	end process;

  -- Implement axi_wready generation
	-- axi_wready is asserted for one s_axi_aclk clock cycle when both
	-- s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	write_ready: process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

  -- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	
  s_wren <= axi_wready and s_axi_wvalid and axi_awready and s_axi_awvalid;

	writing_process: process (s_axi_aclk) 
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '1' then
	      if (s_wren = '1') then
          -- Respective byte enables are asserted as per write strobes 
	        if (to_integer(unsigned(s_axi_wstrb)) = 0) then
            mem_ram_b0(to_integer(unsigned(axi_write_addr))) <= std_ulogic_vector(s_axi_wdata(07 downto 0));
          end if;
          if (to_integer(unsigned(s_axi_wstrb)) = 1) then
            mem_ram_b1(to_integer(unsigned(axi_write_addr))) <= std_ulogic_vector(s_axi_wdata(15 downto 8));
          end if;
          if (to_integer(unsigned(s_axi_wstrb)) = 2) then
            mem_ram_b2(to_integer(unsigned(axi_write_addr))) <= std_ulogic_vector(s_axi_wdata(23 downto 16));
          end if;
          if (to_integer(unsigned(s_axi_wstrb)) = 3) then
            mem_ram_b3(to_integer(unsigned(axi_write_addr))) <= std_ulogic_vector(s_axi_wdata(31 downto 24));
          end if;
        end if;
	    end if;
	  end if;                   
	end process;

  -- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	write_response: process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (s_axi_bready = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process;

  -- Implement axi_arready generation
	-- axi_arready is asserted for one s_axi_aclk clock cycle when
	-- s_axi_arvalid is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when s_axi_arvalid is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	read_ready: process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then 
	    if s_axi_aresetn = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and s_axi_arvalid = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= s_axi_araddr;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process;

  -- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one s_axi_aclk clock cycle when both 
	-- s_axi_arvalid and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	
  read_valid: process (s_axi_aclk)
	begin
	  if rising_edge(s_axi_aclk) then
	    if s_axi_aresetn = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and s_axi_arvalid = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

  -- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	
  s_ren <= axi_arready and s_axi_arvalid and (not axi_rvalid);

	read_trigger: process (mem_ram_b0, mem_ram_b1, mem_ram_b2, mem_ram_b3, axi_araddr, s_axi_aresetn, s_ren)
	begin
	    -- Address decoding for reading registers
	    reg_data_out <= mem_ram_b3_rd & mem_ram_b2_rd & mem_ram_b1_rd & mem_ram_b0_rd;
	end process; 

	-- Output register or memory read data
	reading_process: process( s_axi_aclk ) is
	begin
	  if (rising_edge (s_axi_aclk)) then
	    if ( s_axi_aresetn = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (s_ren = '1') then
	        -- When there is a valid read address (s_axi_arvalid) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= std_logic_vector(reg_data_out);     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;

end neorv32_dmem_rtl;
