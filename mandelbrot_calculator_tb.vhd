-------------------------------------------------------------------------------
-- Title       : mandelbrot_calculator_tb
-- Project     : MSE Mandelbrot
-------------------------------------------------------------------------------
-- File        : mandelbrot_calculator_tb.vhd
-- Authors     : Vivien Kaltenrieder
-- Company     : HES-SO
-- Created     : 28.05.2018
-- Last update : 28.05.2018
-- Platform    : Vivado (synthesis)
-- Standard    : VHDL'08
-------------------------------------------------------------------------------
-- Description: simulation stimulis for mandelbrot_calculator
-------------------------------------------------------------------------------
-- Copyright (c) 2018 HES-SO, Lausanne
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 28.03.2018   0.0      VKR      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity mandelbrot_calculator_tb is
generic (
    comma : integer := 12; -- nombre de bits après la virgule
    max_iter : integer := 100;
    SIZE : integer := 16);
end mandelbrot_calculator_tb;

architecture testbench of mandelbrot_calculator_tb is

  -- Input/output of the DUV
  signal clk_sti          : std_logic;
  signal rst_sti          : std_logic;
  signal ready_obs        : std_logic;
  signal start_sti        : std_logic;
  signal finished_obs     : std_logic;
  signal c_real_sti       : std_logic_vector(SIZE-1 downto 0);
  signal c_imaginary_sti  : std_logic_vector(SIZE-1 downto 0);
  signal z_real_obs       : std_logic_vector(SIZE-1 downto 0);
  signal z_imaginary_obs  : std_logic_vector(SIZE-1 downto 0);
  signal iterations_obs   : std_logic_vector(SIZE-1 downto 0);

  -- Internal singals
  signal sim_end_s : boolean := false; -- put true to end

  component mandelbrot_calculator is
  generic (
      comma : integer := 12; -- nombre de bits après la virgule
      max_iter : integer := 100;
      SIZE : integer := 16);

      port(
          clk_i         : in std_logic;
          rst_i         : in std_logic;
          ready_o       : out std_logic;
          start_i       : in std_logic;
          finished_o    : out std_logic;
          c_real_i      : in std_logic_vector(SIZE-1 downto 0);
          c_imaginary_i : in std_logic_vector(SIZE-1 downto 0);
          z_real_o      : out std_logic_vector(SIZE-1 downto 0);
          z_imaginary_o : out std_logic_vector(SIZE-1 downto 0);
          iterations_o  : out std_logic_vector(SIZE-1 downto 0)
      );
  end component;

begin
    duv : mandelbrot_calculator
    generic map (
        comma       => comma,
        max_iter    => max_iter,
        SIZE        => SIZE
    )
    port map (
      clk_i         => clk_sti,
      rst_i         => rst_sti,
      ready_o       => ready_obs,
      start_i       => start_sti,
      finished_o    => finished_obs,
      c_real_i      => c_real_sti,
      c_imaginary_i => c_imaginary_sti,
      z_real_o      => z_real_obs,
      z_imaginary_o => z_imaginary_obs,
      iterations_o  => iterations_obs
    );

    ----------------------------------------------
    -- stimulus_proc                        ---------
    ----------------------------------------------
    stimulus_proc : process is
    begin
      start_sti <= '0';
      -- begin with a reset
      rst_sti <= '1';
      wait for 10 ns;
 --     c_real_sti <= "0000" & "011000010100";
 --     c_imaginary_sti <= "0000" & "001100110011";
     c_real_sti <= "0000" & "000000000000";
     c_imaginary_sti <= "0001" & "000000000000";
      wait for 20 ns;
      rst_sti <= '0';
      wait for 10 ns;
      start_sti <= '1';
      wait for 2 ns;
      start_sti <= '0';
      
         
      wait for 500 ns;
       
      --while finished_obs = '0' loop
       --do nothing, juste wait the end of the calcul
      --end loop;

      sim_end_s <= true;
      wait; -- Stop the process
    end process; --stimulus_proc
  ----------------------------------------------
  -- clock_proc                        ---------
  ----------------------------------------------
  clock_proc : process
  begin
    while sim_end_s = false loop
      clk_sti <= '1';
      wait for 1 ns;
      clk_sti <= '0';
    wait for 1 ns;
    end loop;
    wait; -- Stop the process
  end process; --clock_proc

end testbench;
