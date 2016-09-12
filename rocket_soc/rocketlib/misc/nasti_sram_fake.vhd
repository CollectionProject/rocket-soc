-----------------------------------------------------------------------------
--! @file
--! @copyright Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author    Sergey Khabarov - sergeykhbr@gmail.com
--! @brief     Internal SRAM module with the byte access
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library techmap;
use techmap.gencomp.all;
use techmap.types_mem.all;

library commonlib;
use commonlib.types_common.all;

--! AMBA system bus specific library.
library ambalib;
--! AXI4 configuration constants.
use ambalib.types_amba4.all;


entity nasti_sram_fake is
  generic (
    memtech  : integer := inferred;
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#;
    abits    : integer := 17;
    abits_real : integer := 17;
    init_file : string := "" -- only for inferred
  );
  port (
    clk  : in std_logic;
    nrst : in std_logic;
    cfg  : out nasti_slave_config_type;
    i    : in  nasti_slave_in_type;
    o    : out nasti_slave_out_type
  );
end; 
 
architecture arch_nasti_sram_fake of nasti_sram_fake is

  constant xconfig : nasti_slave_config_type := (
     xindex => xindex,
     xaddr => conv_std_logic_vector(xaddr, CFG_NASTI_CFG_ADDR_BITS),
     xmask => conv_std_logic_vector(xmask, CFG_NASTI_CFG_ADDR_BITS),
     vid => VENDOR_GNSSSENSOR,
     did => GNSSSENSOR_SRAM,
     descrtype => PNP_CFG_TYPE_SLAVE,
     descrsize => PNP_CFG_SLAVE_DESCR_BYTES
  );

  type registers is record
    bank_axi : nasti_slave_bank_type;
  end record;
  
  type ram_in_type is record
    raddr : global_addr_array_type;
    waddr : global_addr_array_type;
    we    : std_logic;
    wstrb : std_logic_vector(CFG_NASTI_DATA_BYTES-1 downto 0);
    wdata : std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
  end record;

signal r, rin : registers;

signal rdata : std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
signal rami : ram_in_type;

begin

  comblogic : process(i, r, rdata)
    variable v : registers;
    variable vrami : ram_in_type;
    constant SUPPLEMENT_ZERO : std_logic_vector(abits-abits_real-1 downto 0) := (others=>'0');
  begin

    v := r;


    procedureAxi4(i, xconfig, r.bank_axi, v.bank_axi);

    vrami.we := '0';
    vrami.waddr := (others => (others => '0'));
    vrami.wdata := (others => '0');
    vrami.wstrb := (others => '0');
    vrami.raddr := v.bank_axi.raddr;

    if (i.w_valid = '1' and r.bank_axi.wstate = wtrans 
        and r.bank_axi.wresp = NASTI_RESP_OKAY
        ) then
      vrami.we := '1';
      vrami.wdata := i.w_data;
      vrami.wstrb := i.w_strb;
      vrami.waddr := r.bank_axi.waddr;
    end if;

    o <= functionAxi4Output(r.bank_axi, rdata);
    rami <= vrami;
    rin <= v;
  end process;

  cfg  <= xconfig;
  
  tech0 : srambytes_tech generic map (
    memtech   => memtech,
    abits     => abits_real,
    init_file => init_file -- only for 'inferred'
  ) port map (
    clk     => clk,
    raddr   => rami.raddr,
    rdata   => rdata,
    waddr   => rami.waddr,
    we      => rami.we,
    wstrb   => rami.wstrb,
    wdata   => rami.wdata
  );

  -- registers:
  regs : process(clk, nrst)
  begin 
     if nrst = '0' then
        r.bank_axi <= NASTI_SLAVE_BANK_RESET;
     elsif rising_edge(clk) then 
        r <= rin;
     end if; 
  end process;

end;
