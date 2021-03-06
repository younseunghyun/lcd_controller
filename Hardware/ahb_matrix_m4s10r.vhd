-------------------------------------------------------------
-- AHB Bus Matrix (Parameterized Version)
-- This file is a part of SNU AMBA package
-- Generated by PlatformGen
--
-- Date : 2004. 04. 25
-- Author : Sanggyu, Park (Ph.D Candidate of SoEE, SNU)
-- Generation Engine Author : Moonmo, Koo (Ph.D Candidate of SoEE, SNU)
-- Copyright 2004  Seoul National University, Seoul, Korea
-- ALL RIGHTS RESERVED
--------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;

library Work;
use Work.AMBA.all;

-- synthesis translate_off

--library SoCBaseSim;
--use SoCBaseSim.AMBA.all;

-- synthesis translate_on

entity ahb_matrix_m4s10r is

port (
HCLK    :   in std_logic;
HRESETn :   in std_logic;

-- Master/Slave Component Interface
MASTEROUT:  in AHB_MASTEROUT_ARRAY(0 to 3);
SLAVEOUT:   in AHB_SLAVEOUT_ARRAY(0 to 9);

MASTERIN:   out AHB_MASTERIN_ARRAY(0 to 3);
SLAVEIN:    out AHB_SLAVEIN_ARRAY(0 to 9);

-- Decoder Interface
HSLAVEID :  in std_logic_vector(3 downto 0);
DECADDR:    out std_logic_vector(31 downto 0);

-- Global Bus State
BUSSTATE:   out AHB_REC
);
end ahb_matrix_m4s10r;

architecture BEHAVIORAL of ahb_matrix_m4s10r is

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

constant MCNT : integer := 4;
constant SCNT : integer := 10;

signal reg_data_master : std_logic_vector(3 downto 0);
signal reg_data_slave : std_logic_vector(3 downto 0);

signal sig_haddr : std_logic_vector(31 downto 0);
signal sig_htrans : std_logic_vector(1 downto 0);
signal sig_hburst : std_logic_vector(2 downto 0);
signal sig_hsize : std_logic_vector(2 downto 0);
signal sig_hprot : std_logic_vector(3 downto 0);
signal sig_hlock : std_logic;
signal sig_hwdata : std_logic_vector(31 downto 0);
signal sig_hwrite : std_logic;
signal sig_hrdata : std_logic_vector(31 downto 0);
signal sig_hready : std_logic;
signal sig_hresp : std_logic_vector(1 downto 0);
signal sig_hbusreq : std_logic_vector(MCNT-1 downto 0);
signal sig_hgrant : std_logic_vector(MCNT-1 downto 0);
signal sig_hsel : std_logic_vector(SCNT-1 downto 0);
signal sig_hsplit : std_logic_vector(MCNT-1 downto 0);
signal sig_hlock_vector : std_logic_vector(MCNT-1 downto 0);

signal zero : std_logic_vector(31 downto 0);

-- Arbitration Signals

signal next_master, next_high_master, curr_master : std_logic_vector (3 downto 0);
signal sig_handover_allowed : std_logic;    -- Hand-over the bus ownership to other master after
-- current transaction is completed.
signal sig_preempt_allowed : std_logic;     -- Hand-over the bus ownership to next master right now.

signal next_cnter, curr_cnter : std_logic_vector (4 downto 0);
signal sig_burst_size : std_logic_vector(4 downto 0);
signal sig_req_assert : std_logic;
signal reg_master_mask : std_logic_vector(15 downto 0);

constant DEFAULT_BUS_MASTER : std_logic_vector(3 downto 0) := "0000";

begin

zero <= (others => '0');

-- Global Bus State Output (For Bus Monitoring)
BUSSTATE.haddr <= sig_haddr;
BUSSTATE.htrans <= sig_htrans;
BUSSTATE.hburst <= sig_hburst;
BUSSTATE.hsize  <= sig_hsize;
BUSSTATE.hprot  <= sig_hprot;
BUSSTATE.hlock  <= sig_hlock;
BUSSTATE.hwdata <= sig_hwdata;
BUSSTATE.hwrite <= sig_hwrite;
BUSSTATE.hrdata <= sig_hrdata;
BUSSTATE.hready <= sig_hready;
BUSSTATE.hresp  <= sig_hresp;
BUSSTATE.hmaster <= curr_master;
BUSSTATE.hbusreq(15 downto MCNT) <= (others => '0');
BUSSTATE.hbusreq(MCNT-1 downto 0) <= sig_hbusreq;
BUSSTATE.hgrant(15 downto MCNT) <= (others => '0');
BUSSTATE.hgrant(MCNT-1 downto 0) <= sig_hgrant;
BUSSTATE.hlockvec(15 downto MCNT) <= (others => '0');
BUSSTATE.hlockvec(MCNT-1 downto 0) <= sig_hlock_vector;
BUSSTATE.hsel(15 downto SCNT) <= (others => '0');
BUSSTATE.hsel(SCNT-1 downto 0)  <= sig_hsel;
BUSSTATE.hsplit(MCNT-1 downto 0)<= sig_hsplit;
BUSSTATE.hsplit(15 downto MCNT) <= (others => '0');

ARB_SPLIT : process(SLAVEOUT)
variable var_split : std_logic_vector(MCNT-1 downto 0);
begin
sig_hsplit <= (others => '0');
var_split := (others => '0');
for i in 0 to SCNT-1 loop
var_split := var_split or SLAVEOUT(i).hsplit(MCNT-1 downto 0);
end loop;
sig_hsplit(MCNT-1 downto 0) <= var_split;
end process ARB_SPLIT;


-- Priority decoder. Next master is selected in round robine manner
ARB_PRIORITY:process(sig_hbusreq, curr_master)
begin

sig_preempt_allowed <= '0';

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

next_high_master <= curr_master;
case curr_master(1 downto 0) is
when "01" => 
if    (sig_hbusreq(2)='1') then next_high_master <= "0010";
elsif (sig_hbusreq(3)='1') then next_high_master <= "0011";
elsif    (sig_hbusreq(0)='1') then next_high_master <= "0000";
elsif    (sig_hbusreq(1)='1') then next_high_master <= "0001";
end if;
when "10" => 
if    (sig_hbusreq(3)='1') then next_high_master <= "0011";
elsif    (sig_hbusreq(0)='1') then next_high_master <= "0000";
elsif    (sig_hbusreq(1)='1') then next_high_master <= "0001";
elsif    (sig_hbusreq(2)='1') then next_high_master <= "0010";
end if;
when "11" => 
if    (sig_hbusreq(0)='1') then next_high_master <= "0000";
elsif (sig_hbusreq(1)='1') then next_high_master <= "0001";
elsif (sig_hbusreq(2)='1') then next_high_master <= "0010";
elsif (sig_hbusreq(3)='1') then next_high_master <= "0011";
end if;
when others =>
if    (sig_hbusreq(1)='1') then next_high_master <= "0001";
elsif (sig_hbusreq(2)='1') then next_high_master <= "0010";
elsif (sig_hbusreq(3)='1') then next_high_master <= "0011";
elsif (sig_hbusreq(0)='1') then next_high_master <= "0000";
end if;
end case;

end process ARB_PRIORITY;

-- var_req_assert signal is high when at least one master is requesting
-- the bus.
ARB_REQ_ASSERT_COMB : process(sig_hbusreq)
variable var_req_assert : std_logic;
begin
var_req_assert := '0';
for i in 0 to MCNT-1 loop
var_req_assert := var_req_assert or sig_hbusreq(i);
end loop;
sig_req_assert <= var_req_assert;
end process ARB_REQ_ASSERT_COMB;

-- sig_burst_size means the count of beats requested by granted master
ARB_SIZE_COMB : process(sig_hburst)
begin

case sig_hburst(2 downto 1) is
when "01" => sig_burst_size <= "00100";
when "10" => sig_burst_size <= "01000";
when "11" => sig_burst_size <= "10000";
when others => sig_burst_size <= "00001";
end case;

end process ARB_SIZE_COMB;

-- sig_handover_allowed signal means bus handover is allowed or not.
ARB_BUS_HANDOVER:process(sig_htrans,sig_hburst,sig_hresp,sig_hready,
curr_cnter, sig_burst_size, sig_hlock,
sig_preempt_allowed)
begin
-- default assigns
next_cnter <= curr_cnter;
sig_handover_allowed <= '0';

if(sig_hlock = '0') then
if(sig_preempt_allowed = '1') then
sig_handover_allowed <= '1';
else
case sig_htrans is
when HTRANS_IDLE =>
next_cnter <= (others=>'0');
sig_handover_allowed <= sig_hready;
when HTRANS_BUSY =>
when HTRANS_NONSEQ =>
if (sig_hburst = HBURST_SINGLE) then
sig_handover_allowed <= '1';
end if;
next_cnter <= unsigned(sig_burst_size) - 1;
when HTRANS_SEQ =>
if (sig_hburst /= HBURST_INCR and sig_hready = '1' and sig_hresp = HRESP_OKAY) then
next_cnter <= unsigned(curr_cnter) - 1;
if (curr_cnter = "00001") then
sig_handover_allowed <= '1';
end if;
elsif(sig_hready = '1' and sig_hresp /= HRESP_OKAY) then
sig_handover_allowed <= '1';
end if;
when others =>
end case;

end if;
end if;

end process ARB_BUS_HANDOVER;

ARB_MASTER_COMB:process (sig_handover_allowed,
sig_req_assert, curr_master, next_high_master)
begin
-- default assigns

next_master <= curr_master;
if(sig_handover_allowed = '1') then
if(sig_req_assert = '1') then
next_master <= next_high_master;
else
next_master <= DEFAULT_BUS_MASTER;
end if;
end if;

end process ARB_MASTER_COMB;

ARB_GRANT_COMB : process(next_master)
begin

for i in 0 to MCNT-1 loop
sig_hgrant(i) <= '0';
end loop;

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

case next_master(1 downto 0) is
when "01" => sig_hgrant(1) <= '1' ;
when "10" => sig_hgrant(2) <= '1' ;
when "11" => sig_hgrant(3) <= '1' ;
when others => sig_hgrant(0) <= '1' ;
end case;

end process ARB_GRANT_COMB;

ARB_SEQR:process(HRESETn,HCLK)
variable var_master_mask : std_logic_vector(MCNT-1 downto 0);
begin
if (HRESETn = '0') then

curr_master <= DEFAULT_BUS_MASTER;
curr_cnter <= (others=>'0');

reg_master_mask <= (others => '0');

elsif (HCLK='1' and HCLK'event) then

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

reg_master_mask <= (others => '0');
var_master_mask := reg_master_mask(MCNT-1 downto 0);
if(sig_hready = '0' and sig_hresp = HRESP_SPLIT) then
case reg_data_master is
when "0000" => var_master_mask(0) := '1';
when "0001" => var_master_mask(1) := '1';
when "0010" => var_master_mask(2) := '1';
when "0011" => var_master_mask(3) := '1';
when others =>
end case;
end if;
reg_master_mask(MCNT-1 downto 0) <= var_master_mask and (not sig_hsplit(MCNT-1 downto 0));

if(sig_hready = '1') then
curr_master <= next_master;
curr_cnter <= next_cnter;
end if;

end if;
end process ARB_SEQR;

------------------------------------------------------------------------------
--% Bus Fabric

DECADDR <= sig_haddr;

DECODESLAVEID : process(HSLAVEID)
begin

sig_hsel <= (others => '0');

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

case HSLAVEID(3 downto 0) is
when "0000" => sig_hsel(0) <= '1';
when "0001" => sig_hsel(1) <= '1';
when "0010" => sig_hsel(2) <= '1';
when "0011" => sig_hsel(3) <= '1';
when "0100" => sig_hsel(4) <= '1';
when "0101" => sig_hsel(5) <= '1';
when "0110" => sig_hsel(6) <= '1';
when "0111" => sig_hsel(7) <= '1';
when "1000" => sig_hsel(8) <= '1';
when "1001" => sig_hsel(9) <= '1';
when others =>
end case;

end process DECODESLAVEID;

BUS_REG : process(HCLK, HRESETn)
begin
if(HRESETn = '0') then
reg_data_master <= (others => '0');
reg_data_slave <= (others => '0');
elsif(HCLK = '1' and HCLK'event) then
if(sig_hready = '1') then
reg_data_master <= curr_master;
reg_data_slave <= HSLAVEID;
end if;
end if;

end process BUS_REG;

-- Master Input Mux Fabric
SINMUXFAB : process(sig_haddr, sig_htrans, sig_hwrite, sig_hsize,
sig_hburst, sig_hlock, sig_hprot, sig_hwdata,
sig_hsel, sig_hready, curr_master, hslaveid)
begin

for i in 0 to SCNT-1 loop
SLAVEIN(i).haddr <= sig_haddr;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).htrans <= sig_htrans;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hwrite <= sig_hwrite;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hsize <= sig_hsize;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hburst <= sig_hburst;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hlock <= sig_hlock;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hprot <= sig_hprot;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hwdata <= sig_hwdata;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hsel <= sig_hsel(i);
end loop;
for i in 0 to SCNT-1 loop
SLAVEIN(i).hreadyin <= sig_hready;
end loop;

for i in 0 to SCNT-1 loop
SLAVEIN(i).hmasterid <= curr_master;
end loop;

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------
for i in 0 to SCNT-1 loop
SLAVEIN(i).hsel <= '0';
end loop;

case HSLAVEID(3 downto 0) is
when "0001" => SLAVEIN(1).hsel <= '1';
when "0010" => SLAVEIN(2).hsel <= '1';
when "0011" => SLAVEIN(3).hsel <= '1';
when "0100" => SLAVEIN(4).hsel <= '1';
when "0101" => SLAVEIN(5).hsel <= '1';
when "0110" => SLAVEIN(6).hsel <= '1';
when "0111" => SLAVEIN(7).hsel <= '1';
when "1000" => SLAVEIN(8).hsel <= '1';
when "1001" => SLAVEIN(9).hsel <= '1';
when others => SLAVEIN(0).hsel <= '1';
end case;

end process SINMUXFAB;

MINMUXFAB : process(sig_hrdata, sig_hready, sig_hresp, sig_hgrant)
begin

for i in 0 to MCNT-1 loop
MASTERIN(i).hgrant <= sig_hgrant(i);
end loop;

for i in 0 to MCNT-1 loop
MASTERIN(i).hrdata <= sig_hrdata;
end loop;

for i in 0 to MCNT-1 loop
MASTERIN(i).hready <= sig_hready;
end loop;

for i in 0 to MCNT-1 loop
MASTERIN(i).hresp <= sig_hresp;
end loop;

end process MINMUXFAB;

-- Master Output Mux Fabric
OUTMUXFAB : process(MASTEROUT, SLAVEOUT, curr_master, reg_data_master,
reg_data_slave, reg_master_mask)
variable var_hready : std_logic;

begin

for i in 0 to MCNT-1 loop
sig_hbusreq(i) <= MASTEROUT(i).hbusreq and (not reg_master_mask(i));
end loop;

var_hready := '1';
for i in 0 to SCNT-1 loop
var_hready := var_hready and SLAVEOUT(i).hready;
end loop;
sig_hready <= var_hready;

for i in 0 to MCNT-1 loop
sig_hlock_vector(i) <= MASTEROUT(i).hlock;
end loop;

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

case curr_master(1 downto 0) is
when "01" =>
sig_haddr <= MASTEROUT(1).haddr;
sig_htrans <= MASTEROUT(1).htrans;
sig_hwrite <= MASTEROUT(1).hwrite;
sig_hsize <= MASTEROUT(1).hsize;
sig_hburst <= MASTEROUT(1).hburst;
sig_hlock <= MASTEROUT(1).hlock;
sig_hprot <= MASTEROUT(1).hprot;
when "10" =>
sig_haddr <= MASTEROUT(2).haddr;
sig_htrans <= MASTEROUT(2).htrans;
sig_hwrite <= MASTEROUT(2).hwrite;
sig_hsize <= MASTEROUT(2).hsize;
sig_hburst <= MASTEROUT(2).hburst;
sig_hlock <= MASTEROUT(2).hlock;
sig_hprot <= MASTEROUT(2).hprot;
when "11" =>
sig_haddr <= MASTEROUT(3).haddr;
sig_htrans <= MASTEROUT(3).htrans;
sig_hwrite <= MASTEROUT(3).hwrite;
sig_hsize <= MASTEROUT(3).hsize;
sig_hburst <= MASTEROUT(3).hburst;
sig_hlock <= MASTEROUT(3).hlock;
sig_hprot <= MASTEROUT(3).hprot;
when others =>
sig_haddr <= MASTEROUT(0).haddr;
sig_htrans <= MASTEROUT(0).htrans;
sig_hwrite <= MASTEROUT(0).hwrite;
sig_hsize <= MASTEROUT(0).hsize;
sig_hburst <= MASTEROUT(0).hburst;
sig_hlock <= MASTEROUT(0).hlock;
sig_hprot <= MASTEROUT(0).hprot;
end case;

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

case reg_data_master(1 downto 0) is
when "01" =>	sig_hwdata <= MASTEROUT(1).hwdata;
when "10" =>	sig_hwdata <= MASTEROUT(2).hwdata;
when "11" =>	sig_hwdata <= MASTEROUT(3).hwdata;
when others =>  sig_hwdata <= MASTEROUT(0).hwdata;
end case;

--------------------------------------------------------------
--% Non-Parameterized Code Region
--------------------------------------------------------------

case reg_data_slave(3 downto 0) is
when "0001" =>
sig_hrdata <= SLAVEOUT(1).hrdata;
sig_hresp <= SLAVEOUT(1).hresp;
when "0010" =>
sig_hrdata <= SLAVEOUT(2).hrdata;
sig_hresp <= SLAVEOUT(2).hresp;
when "0011" =>
sig_hrdata <= SLAVEOUT(3).hrdata;
sig_hresp <= SLAVEOUT(3).hresp;
when "0100" =>
sig_hrdata <= SLAVEOUT(4).hrdata;
sig_hresp <= SLAVEOUT(4).hresp;
when "0101" =>
sig_hrdata <= SLAVEOUT(5).hrdata;
sig_hresp <= SLAVEOUT(5).hresp;
when "0110" =>
sig_hrdata <= SLAVEOUT(6).hrdata;
sig_hresp <= SLAVEOUT(6).hresp;
when "0111" =>
sig_hrdata <= SLAVEOUT(7).hrdata;
sig_hresp <= SLAVEOUT(7).hresp;
when "1000" =>
sig_hrdata <= SLAVEOUT(8).hrdata;
sig_hresp <= SLAVEOUT(8).hresp;
when "1001" =>
sig_hrdata <= SLAVEOUT(9).hrdata;
sig_hresp <= SLAVEOUT(9).hresp;
when others =>
sig_hrdata <= SLAVEOUT(0).hrdata;
sig_hresp <= SLAVEOUT(0).hresp;
end case;

end process OUTMUXFAB;
end BEHAVIORAL;
