-------------------------------------------------------------------------------
-- Title       : MSE Mandelbrot Top Level
-- Project     : MSE Mandelbrot
-------------------------------------------------------------------------------
-- File        : mse_mandelbrot.vhd
-- Authors     : Joachim Schmidt
-- Company     : Hepia
-- Created     : 26.02.2018
-- Last update : 26.02.2018
-- Platform    : Vivado (synthesis)
-- Standard    : VHDL'08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Hepia, Geneve
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 26.02.2018   0.0      SCJ      Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.hdmi_interface_pkg.all;

entity mse_mandelbrot is

    generic (
        C_CHANNEL_NUMBER : integer := 4);

    port (
        ClkSys100MhzxC : in    std_logic;
        RstxR          : in    std_logic;
        -- HDMI
        HdmiTxRsclxSO  : out   std_logic;
        HdmiTxRsdaxSIO : inout std_logic;
        HdmiTxHpdxSI   : in    std_logic;
        HdmiTxCecxSIO  : inout std_logic;
        HdmiTxClkPxSO  : out   std_logic;
        HdmiTxClkNxSO  : out   std_logic;
        HdmiTxPxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0);
        HdmiTxNxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0));

end entity mse_mandelbrot;

architecture rtl of mse_mandelbrot is

    ---------------------------------------------------------------------------
    -- Resolution configuration
    ---------------------------------------------------------------------------
    -- Possible resolutions
    --
    -- 1024x768
    -- 1024x600
    -- 800x600
    -- 640x480

    -- constant C_VGA_CONFIG : t_VgaConfig := C_1024x768_VGACONFIG;
    constant C_VGA_CONFIG : t_VgaConfig := C_1024x600_VGACONFIG;
    -- constant C_VGA_CONFIG : t_VgaConfig := C_800x600_VGACONFIG;
    -- constant C_VGA_CONFIG : t_VgaConfig := C_640x480_VGACONFIG;

    -- constant C_RESOLUTION : string := "1024x768";
    constant C_RESOLUTION : string := "1024x600";
    -- constant C_RESOLUTION : string := "800x600";
    -- constant C_RESOLUTION : string := "640x480";
    ---------------------------------------------------------------------------
    -- 
    ---------------------------------------------------------------------------

    constant C_DATA_SIZE                        : integer := 16;
    constant C_PIXEL_SIZE                       : integer := 8;
    constant C_BRAM_VIDEO_MEMORY_ADDR_SIZE      : integer := 20;
    constant C_BRAM_VIDEO_MEMORY_HIGH_ADDR_SIZE : integer := 10;
    constant C_BRAM_VIDEO_MEMORY_LOW_ADDR_SIZE  : integer := 10;
    constant C_BRAM_VIDEO_MEMORY_DATA_SIZE      : integer := 9;

    component hdmi is
        generic (
            C_CHANNEL_NUMBER : integer;
            C_DATA_SIZE      : integer;
            C_PIXEL_SIZE     : integer;
            C_VGA_CONFIG     : t_VgaConfig;
            C_RESOLUTION     : string);
        port (
            ClkSys100MhzxC : in    std_logic;
            RstxR          : in    std_logic;
            PllLockedxSO   : out   std_logic;
            ClkVgaxCO      : out   std_logic;
            HCountxDO      : out   std_logic_vector((C_DATA_SIZE - 1) downto 0);
            VCountxDO      : out   std_logic_vector((C_DATA_SIZE - 1) downto 0);
            VidOnxSO       : out   std_logic;
            DataxDI        : in    std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0);
            HdmiTxRsclxSO  : out   std_logic;
            HdmiTxRsdaxSIO : inout std_logic;
            HdmiTxHpdxSI   : in    std_logic;
            HdmiTxCecxSIO  : inout std_logic;
            HdmiTxClkPxSO  : out   std_logic;
            HdmiTxClkNxSO  : out   std_logic;
            HdmiTxPxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0);
            HdmiTxNxDO     : out   std_logic_vector((C_CHANNEL_NUMBER - 2) downto 0));
    end component hdmi;

    component image_generator is
        generic (
            C_DATA_SIZE  : integer;
            C_PIXEL_SIZE : integer;
            C_VGA_CONFIG : t_VgaConfig);
        port (
            ClkVgaxC     : in  std_logic;
            RstxRA       : in  std_logic;
            PllLockedxSI : in  std_logic;
            HCountxDI    : in  std_logic_vector((C_DATA_SIZE - 1) downto 0);
            VCountxDI    : in  std_logic_vector((C_DATA_SIZE - 1) downto 0);
            VidOnxSI     : in  std_logic;
            DataxDO      : out std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0));
    end component image_generator;

    -- Pll Locked
    signal PllLockedxS    : std_logic                                           := '0';
    signal RstPllLockedxS : std_logic                                           := '0';
    -- Clocks
    signal ClkVgaxC       : std_logic                                           := '0';
    -- VGA
    signal HCountxD       : std_logic_vector((C_DATA_SIZE - 1) downto 0)        := (others => '0');
    signal VCountxD       : std_logic_vector((C_DATA_SIZE - 1) downto 0)        := (others => '0');
    signal VidOnxS        : std_logic                                           := '0';
    -- Others
    signal DataxD         : std_logic_vector(((C_PIXEL_SIZE * 3) - 1) downto 0) := (others => '0');
    signal HdmiSourcexD   : t_HdmiSource                                        := C_NO_HDMI_SOURCE;

    -- Debug signals

    -- attribute mark_debug                               : string;
    -- attribute mark_debug of HCountxD                   : signal is "true";
    -- attribute mark_debug of VCountxD                   : signal is "true";
    -- attribute mark_debug of DataImGen2BramMVxD         : signal is "true";
    -- attribute mark_debug of DataBramMV2HdmixD          : signal is "true";
    -- attribute mark_debug of BramVideoMemoryWriteAddrxD : signal is "true";
    -- attribute mark_debug of BramVideoMemoryReadAddrxD  : signal is "true";
    -- attribute mark_debug of BramVideoMemoryWriteDataxD : signal is "true";
    -- attribute mark_debug of BramVideoMemoryReadDataxD  : signal is "true";

    -- attribute keep                               : string;
    -- attribute keep of HCountxD                   : signal is "true";
    -- attribute keep of VCountxD                   : signal is "true";
    -- attribute keep of DataImGen2BramMVxD         : signal is "true";
    -- attribute keep of DataBramMV2HdmixD          : signal is "true";
    -- attribute keep of BramVideoMemoryWriteAddrxD : signal is "true";
    -- attribute keep of BramVideoMemoryReadAddrxD  : signal is "true";
    -- attribute keep of BramVideoMemoryWriteDataxD : signal is "true";
    -- attribute keep of BramVideoMemoryReadDataxD  : signal is "true";

begin  -- architecture rtl

    -- Asynchronous statements

    assert ((C_VGA_CONFIG = C_640x480_VGACONFIG) and (C_RESOLUTION = "640x480"))
        or ((C_VGA_CONFIG = C_800x600_VGACONFIG) and (C_RESOLUTION = "800x600"))
        or ((C_VGA_CONFIG = C_1024x600_VGACONFIG) and (C_RESOLUTION = "1024x600"))
        or ((C_VGA_CONFIG = C_1024x768_VGACONFIG) and (C_RESOLUTION = "1024x768"))
        report "Not supported resolution!" severity failure;

    HdmiSourceOutxB : block is
    begin  -- block HdmiSourceOutxB

        HdmiTxRsclxAS : HdmiTxRsclxSO                           <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxRsclxS;
        HdmiTxRsdaxAS : HdmiTxRsdaxSIO                          <= HdmiSourcexD.HdmiSourceInOutxS.HdmiTxRsdaxS;
        HdmiTxHpdxAS  : HdmiSourcexD.HdmiSourceInxS.HdmiTxHpdxS <= HdmiTxHpdxSI;
        HdmiTxCecxAS  : HdmiTxCecxSIO                           <= HdmiSourcexD.HdmiSourceInOutxS.HdmiTxCecxS;
        HdmiTxClkPxAS : HdmiTxClkPxSO                           <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkPxS;
        HdmiTxClkNxAS : HdmiTxClkNxSO                           <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkNxS;
        HdmiTxPxAS    : HdmiTxPxDO                              <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxPxD;
        HdmiTxNxAS    : HdmiTxNxDO                              <= HdmiSourcexD.HdmiSourceOutxD.HdmiTxNxD;

    end block HdmiSourceOutxB;

    ---------------------------------------------------------------------------
    -- HDMI Interface
    ---------------------------------------------------------------------------
    HdmixI : entity work.hdmi
        generic map (
            C_CHANNEL_NUMBER => C_CHANNEL_NUMBER,
            C_DATA_SIZE      => C_DATA_SIZE,
            C_PIXEL_SIZE     => C_PIXEL_SIZE,
            C_VGA_CONFIG     => C_VGA_CONFIG,
            C_RESOLUTION     => C_RESOLUTION)
        port map (
            ClkSys100MhzxC => ClkSys100MhzxC,
            RstxR          => RstxR,
            PllLockedxSO   => PllLockedxS,
            ClkVgaxCO      => ClkVgaxC,
            HCountxDO      => HCountxD,
            VCountxDO      => VCountxD,
            VidOnxSO       => VidOnxS,
            DataxDI        => DataxD,
            HdmiTxRsclxSO  => HdmiSourcexD.HdmiSourceOutxD.HdmiTxRsclxS,
            HdmiTxRsdaxSIO => HdmiSourcexD.HdmiSourceInOutxS.HdmiTxRsdaxS,
            HdmiTxHpdxSI   => HdmiSourcexD.HdmiSourceInxS.HdmiTxHpdxS,
            HdmiTxCecxSIO  => HdmiSourcexD.HdmiSourceInOutxS.HdmiTxCecxS,
            HdmiTxClkPxSO  => HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkPxS,
            HdmiTxClkNxSO  => HdmiSourcexD.HdmiSourceOutxD.HdmiTxClkNxS,
            HdmiTxPxDO     => HdmiSourcexD.HdmiSourceOutxD.HdmiTxPxD,
            HdmiTxNxDO     => HdmiSourcexD.HdmiSourceOutxD.HdmiTxNxD);

    RstPllLockedxB : block is
    begin  -- block RstPllLockedxB

        RstPllLockedxAS : RstPllLockedxS <= not PllLockedxS;

    end block RstPllLockedxB;

    ImageGeneratorxB : block is
    begin  -- block ImageGeneratorxB

        ---------------------------------------------------------------------------
        -- Image generator example
        ---------------------------------------------------------------------------
        ImageGeneratorxI : entity work.image_generator
            generic map (
                C_DATA_SIZE  => C_DATA_SIZE,
                C_PIXEL_SIZE => C_PIXEL_SIZE,
                C_VGA_CONFIG => C_VGA_CONFIG)
            port map (
                ClkVgaxC     => ClkVgaxC,
                RstxRA       => RstPllLockedxS,
                PllLockedxSI => PllLockedxS,
                HCountxDI    => HCountxD,
                VCountxDI    => VCountxD,
                VidOnxSI     => VidOnxS,
                DataxDO      => DataxD);

    end block ImageGeneratorxB;

end architecture rtl;
