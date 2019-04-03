-------------------------------------------------------------------------------
-- Title      : Testbench for design "AD9249ClkUS"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ePixHr10kT_full_tb.vhd
-- Author     : Dionisio Doering  <ddoering@tid-pc94280.slac.stanford.edu>
-- Company    : 
-- Created    : 2017-05-22
-- Last update: 2019-04-03
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

library STD;
use STD.textio.all;      
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

use work.all;
use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.EpixHrCorePkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.Pgp2bPkg.all;
use work.SsiPkg.all;
use work.SsiCmdMasterPkg.all;
use work.HrAdcPkg.all;
use work.Code8b10bPkg.all;
use work.AppPkg.all;
use work.BuildInfoPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------

entity ePixHr10kT_full_tb is
     generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType := BUILD_INFO_C);
end ePixHr10kT_full_tb;

-------------------------------------------------------------------------------

architecture arch of ePixHr10kT_full_tb is


  --file definitions
  constant DATA_BITS   : natural := 16;
  constant DEPTH_C     : natural := 1024;
  constant FILENAME_C  : string  := "/afs/slac.stanford.edu/u/re/ddoering/localGit/epix-hr-dev/firmware/simulations/CryoEncDec/sin.csv";
  subtype word_t  is slv(DATA_BITS - 1 downto 0);
  type    ram_t   is array(0 to DEPTH_C - 1) of word_t;

  impure function readWaveFile(FileName : STRING) return ram_t is
    file     FileHandle   : TEXT open READ_MODE is FileName;
    variable CurrentLine  : LINE;
    variable TempWord     : integer; --slv(DATA_BITS - 1 downto 0);
    variable TempWordSlv  : slv(16 - 1 downto 0);
    variable Result       : ram_t    := (others => (others => '0'));
  begin
    for i in 0 to DEPTH_C - 1 loop
      exit when endfile(FileHandle);
      readline(FileHandle, CurrentLine);
      read(CurrentLine, TempWord);
      TempWordSlv  := toSlv(TempWord, 16);
      Result(i)    := TempWordSlv(15 downto 16 - DATA_BITS);
    end loop;
    return Result;
  end function;

  -- waveform signal
  signal ramWaveform      : ram_t    := readWaveFile(FILENAME_C);
  signal ramTestWaveform  : ram_t    := readWaveFile(FILENAME_C);


  -----------------------------------------------------------------------------
  -- Signals to mimic top module io
  -----------------------------------------------------------------------------
      -----------------------
      -- Application Ports --
      -----------------------
      -- System Ports
      signal digPwrEn      : sl;
      signal anaPwrEn      : sl;
      signal syncDigDcDc   : sl;
      signal syncAnaDcDc   : sl;
      signal syncDcDc      : slv(6 downto 0);
      signal daqTg         : sl;
      signal connTgOut     : sl;
      signal connMps       : sl;
      signal connRun       : sl;
      -- Fast ADC Ports
      signal adcSpiClk     : sl;
      signal adcSpiData    : sl;
      signal adcSpiCsL     : sl;
      signal adcPdwn       : sl;
      signal adcClkP       : sl;
      signal adcClkM       : sl;
      signal adcDoClkP     : sl;
      signal adcDoClkM     : sl;
      signal adcFrameClkP  : sl;
      signal adcFrameClkM  : sl;
      signal adcMonDoutP   : slv(4 downto 0);
      signal adcMonDoutN   : slv(4 downto 0);
      -- Slow ADC
      signal slowAdcSclk   : sl;
      signal slowAdcDin    : sl;
      signal slowAdcCsL    : sl;
      signal slowAdcRefClk : sl;
      signal slowAdcDout   : sl;
      signal slowAdcDrdy   : sl;
      signal slowAdcSync   : sl;
      -- Slow DACs Port
      signal sDacCsL       : slv(4 downto 0);
      signal hsDacCsL      : sl;
      signal hsDacLoad     : sl;
      signal dacClrL       : sl;
      signal dacSck        : sl;
      signal dacDin        : sl;
      -- ASIC Gbps Ports
      signal asicDataP     : slv(23 downto 0);
      signal asicDataN     : slv(23 downto 0);
      -- ASIC Control Ports
      signal asicR0        : sl;
      signal asicPpmat     : sl;
      signal asicGlblRst   : sl;
      signal asicSync      : sl;
      signal asicAcq       : sl;
      signal asicRoClkP    : slv(3 downto 0);
      signal asicRoClkN    : slv(3 downto 0);
      -- SACI Ports
      signal asicSaciCmd   : sl;
      signal asicSaciClk   : sl;
      signal asicSaciSel   : slv(3 downto 0);
      signal asicSaciRsp   : sl;
      -- Spare Ports
      signal spareHpP      : slv(11 downto 0);
      signal spareHpN      : slv(11 downto 0);
      signal spareHrP      : slv(5 downto 0);
      signal spareHrN      : slv(5 downto 0);
      -- GTH Ports
      signal gtRxP         : sl;
      signal gtRxN         : sl;
      signal gtTxP         : sl;
      signal gtTxN         : sl;
      signal gtRefP        : sl;
      signal gtRefN        : sl;
      signal smaRxP        : sl;
      signal smaRxN        : sl;
      signal smaTxP        : sl;
      signal smaTxN        : sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- Board IDs Ports
      signal snIoAdcCard   : sl;
      signal snIoCarrier   : sl;
      -- QSFP Ports
      signal qsfpRxP       : slv(3 downto 0);
      signal qsfpRxN       : slv(3 downto 0);
      signal qsfpTxP       : slv(3 downto 0);
      signal qsfpTxN       : slv(3 downto 0);
      signal qsfpClkP      : sl := '1';
      signal qsfpClkN      : sl;
      signal qsfpLpMode    : sl;
      signal qsfpModSel    : sl;
      signal qsfpInitL     : sl;
      signal qsfpRstL      : sl;
      signal qsfpPrstL     : sl;
      signal qsfpScl       : sl;
      signal qsfpSda       : sl;
      -- DDR Ports
      signal ddrClkP       : sl := '1';
      signal ddrClkN       : sl;
      signal ddrBg         : sl;
      signal ddrCkP        : sl;
      signal ddrCkN        : sl;
      signal ddrCke        : sl;
      signal ddrCsL        : sl;
      signal ddrOdt        : sl;
      signal ddrAct        : sl;
      signal ddrRstL       : sl;
      signal ddrA          : slv(16 downto 0);
      signal ddrBa         : slv(1 downto 0);
      signal ddrDm         : slv(3 downto 0);
      signal ddrDq         : slv(31 downto 0);
      signal ddrDqsP       : slv(3 downto 0);
      signal ddrDqsN       : slv(3 downto 0);
      signal ddrPg         : sl;
      signal ddrPwrEn      : sl;
      -- SYSMON Ports
      signal vPIn          : sl;
      signal vNIn          : sl;
  
  -----------------------------------------------------------------------------
  -- Signals to communicate among app and core
  -----------------------------------------------------------------------------
  -- System Clock and Reset
  signal sysClk          : sl;
  signal sysRst          : sl;
  -- AXI-Lite Register Interface (sysClk domain)
  signal axilReadMaster  : AxiLiteReadMasterType;
  signal axilReadSlave   : AxiLiteReadSlaveType;
  signal axilWriteMaster : AxiLiteWriteMasterType;
  signal axilWriteSlave  : AxiLiteWriteSlaveType;
  -- AXI Stream, one per QSFP lane (sysClk domain)
  signal axisMasters     : AxiStreamMasterArray(3 downto 0);
  signal axisSlaves      : AxiStreamSlaveArray(3 downto 0);
  -- Auxiliary AXI Stream, (sysClk domain)
  signal sAuxAxisMasters : AxiStreamMasterArray(1 downto 0);
  signal sAuxAxisSlaves  : AxiStreamSlaveArray(1 downto 0);
  -- ssi commands (Lane and Vc 0)
  signal ssiCmd          : SsiCmdMasterType;
  -- DDR's AXI Memory Interface (sysClk domain)
  signal axiReadMaster   : AxiReadMasterType;
  signal axiReadSlave    : AxiReadSlaveType;
  signal axiWriteMaster  : AxiWriteMasterType;
  signal axiWriteSlave   : AxiWriteSlaveType;
  -- Microblaze's Interrupt bus (sysClk domain)
  signal mbIrq           : slv(7 downto 0);


begin  --

  -- clock generation
  qsfpClkP  <= not qsfpClkP after 6.4 ns;
  qsfpClkN  <= not qsfpClkP;

  ddrClkP  <= not ddrCkP after 6.4 ns;
  ddrClkN  <= not ddrCkP;

  
  -- waveform generation
  WaveGen_Proc: process
    variable registerData    : slv(31 downto 0);  
  begin

    ---------------------------------------------------------------------------
    -- reset
    ---------------------------------------------------------------------------
    wait until sysClk = '1';
   
    wait;
  end process WaveGen_Proc;

  U_App : entity work.Application
      generic map (
         TPD_G => TPD_G,
         SIMULATION_G => True,
         BUILD_INFO_G => BUILD_INFO_G)
      port map (
         ----------------------
         -- Top Level Interface
         ----------------------
         -- System Clock and Reset
         sysClk           => sysClk,
         sysRst           => sysRst,
         -- AXI-Lite Register Interface (sysClk domain)
         -- Register Address Range = [0x80000000:0xFFFFFFFF]
         sAxilReadMaster  => axilReadMaster,
         sAxilReadSlave   => axilReadSlave,
         sAxilWriteMaster => axilWriteMaster,
         sAxilWriteSlave  => axilWriteSlave,
         -- AXI Stream, one per QSFP lane (sysClk domain)
         mAxisMasters     => axisMasters,
         mAxisSlaves      => axisSlaves,
         -- Auxiliary AXI Stream, (sysClk domain)
         sAuxAxisMasters  => sAuxAxisMasters,
         sAuxAxisSlaves   => sAuxAxisSlaves,
         ssiCmd           => ssiCmd,
         -- DDR's AXI Memory Interface (sysClk domain)
         -- DDR Address Range = [0x00000000:0x3FFFFFFF]
         mAxiReadMaster   => axiReadMaster,
         mAxiReadSlave    => axiReadSlave,
         mAxiWriteMaster  => axiWriteMaster,
         mAxiWriteSlave   => axiWriteSlave,
         -- Microblaze's Interrupt bus (sysClk domain)
         mbIrq            => mbIrq,
         -----------------------
         -- Application Ports --
         -----------------------
         -- System Ports
         digPwrEn         => digPwrEn,
         anaPwrEn         => anaPwrEn,
         syncDigDcDc      => syncDigDcDc,
         syncAnaDcDc      => syncAnaDcDc,
         syncDcDc         => syncDcDc,
         led              => open,
         daqTg            => daqTg,
         connTgOut        => connTgOut,
         connMps          => connMps,
         connRun          => connRun,
         -- Fast ADC Ports
         adcSpiClk        => adcSpiClk,
         adcSpiData       => adcSpiData,
         adcSpiCsL        => adcSpiCsL,
         adcPdwn          => adcPdwn,
         adcClkP          => adcClkP,
         adcClkM          => adcClkM,
         adcDoClkP        => adcDoClkP,
         adcDoClkM        => adcDoClkM,
         adcFrameClkP     => adcFrameClkP,
         adcFrameClkM     => adcFrameClkM,
         adcMonDoutP      => adcMonDoutP,
         adcMonDoutN      => adcMonDoutN,
         -- Slow ADC
         slowAdcSclk      => slowAdcSclk,
         slowAdcDin       => slowAdcDin,
         slowAdcCsL       => slowAdcCsL,
         slowAdcRefClk    => slowAdcRefClk,
         slowAdcDout      => slowAdcDout,
         slowAdcDrdy      => slowAdcDrdy,
         slowAdcSync      => slowAdcSync,
         -- Slow DACs Port         
         sDacCsL          => sDacCsL,
         hsDacCsL         => hsDacCsL,
         hsDacLoad        => hsDacLoad,
         dacClrL          => dacClrL,
         dacSck           => dacSck,
         dacDin           => dacDin,
         -- ASIC Gbps Ports
         asicDataP        => asicDataP,
         asicDataN        => asicDataN,
         -- ASIC Control Ports
         asicR0           => asicR0,
         asicPpmat        => asicPpmat,
         asicGlblRst      => asicGlblRst,
         asicSync         => asicSync,
         asicAcq          => asicAcq,
         asicRoClkP       => asicRoClkP,
         asicRoClkN       => asicRoClkN,
         -- SACI Ports
         asicSaciCmd      => asicSaciCmd,
         asicSaciClk      => asicSaciClk,
         asicSaciSel      => asicSaciSel,
         asicSaciRsp      => asicSaciRsp,
         -- Spare Ports
         spareHpP         => spareHpP,
         spareHpN         => spareHpN,
         spareHrP         => spareHrP,
         spareHrN         => spareHrN,
         -- GTH Ports
         gtRxP            => gtRxP,
         gtRxN            => gtRxN,
         gtTxP            => gtTxP,
         gtTxN            => gtTxN,
         gtRefP           => gtRefP,
         gtRefN           => gtRefN,
         smaRxP           => smaRxP,
         smaRxN           => smaRxN,
         smaTxP           => smaTxP,
         smaTxN           => smaTxN);

  U_Core : entity work.EpixHrCore
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         SIMULATION_G => true)
      port map (
         ----------------------
         -- Top Level Interface
         ----------------------
         -- System Clock and Reset
         sysClk           => sysClk,
         sysRst           => sysRst,
         -- AXI-Lite Register Interface (sysClk domain)
         -- Register Address Range = [0x80000000:0xFFFFFFFF]
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave,
         -- AXI Stream, one per QSFP lane (sysClk domain)
         sAxisMasters     => axisMasters,
         sAxisSlaves      => axisSlaves,
         -- Auxiliary AXI Stream, (sysClk domain)
         sAuxAxisMasters  => sAuxAxisMasters,
         sAuxAxisSlaves   => sAuxAxisSlaves,
         ssiCmd           => ssiCmd,
         -- DDR's AXI Memory Interface (sysClk domain)
         -- DDR Address Range = [0x00000000:0x3FFFFFFF]
         sAxiReadMaster   => axiReadMaster,
         sAxiReadSlave    => axiReadSlave,
         sAxiWriteMaster  => axiWriteMaster,
         sAxiWriteSlave   => axiWriteSlave,
         -- Microblaze's Interrupt bus (sysClk domain)
         mbIrq            => mbIrq,
         ----------------
         -- Core Ports --
         ----------------   
         -- Board IDs Ports
         snIoAdcCard      => snIoAdcCard,
         snIoCarrier      => snIoCarrier,
         -- QSFP Ports
         qsfpRxP          => qsfpRxP,
         qsfpRxN          => qsfpRxN,
         qsfpTxP          => qsfpTxP,
         qsfpTxN          => qsfpTxN,
         qsfpClkP         => qsfpClkP,
         qsfpClkN         => qsfpClkN,
         qsfpLpMode       => qsfpLpMode,
         qsfpModSel       => qsfpModSel,
         qsfpInitL        => qsfpInitL,
         qsfpRstL         => qsfpRstL,
         qsfpPrstL        => qsfpPrstL,
         qsfpScl          => qsfpScl,
         qsfpSda          => qsfpSda,
         -- DDR Ports
         ddrClkP          => ddrClkP,
         ddrClkN          => ddrClkN,
         ddrBg            => ddrBg,
         ddrCkP           => ddrCkP,
         ddrCkN           => ddrCkN,
         ddrCke           => ddrCke,
         ddrCsL           => ddrCsL,
         ddrOdt           => ddrOdt,
         ddrAct           => ddrAct,
         ddrRstL          => ddrRstL,
         ddrA             => ddrA,
         ddrBa            => ddrBa,
         ddrDm            => ddrDm,
         ddrDq            => ddrDq,
         ddrDqsP          => ddrDqsP,
         ddrDqsN          => ddrDqsN,
         ddrPg            => ddrPg,
         ddrPwrEn         => ddrPwrEn,
         -- SYSMON Ports
         vPIn             => vPIn,
         vNIn             => vNIn);  

end arch;

