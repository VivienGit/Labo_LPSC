-------------------------------------------------------------------------------
-- Title       : mandelbrot_calculator
-- Project     : MSE Mandelbrot
-------------------------------------------------------------------------------
-- File        : mandelbrot_calculator.vhd
-- Authors     : Vivien Kaltenrieder
-- Company     : HES-SO
-- Created     : 23.05.2018
-- Last update : 23.05.2018
-- Platform    : Vivado (synthesis)
-- Standard    : VHDL'08
-------------------------------------------------------------------------------
-- Description: mandelbrot_calculator
-------------------------------------------------------------------------------
-- Copyright (c) 2018 HES-SO, Lausanne
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 25.03.2018   0.0      VKR      Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity mandelbrot_calculator is
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
end mandelbrot_calculator;

architecture Calculator of mandelbrot_calculator is

  -- Stat machine states
  constant WAIT_start_i_STATE : std_logic_vector := "00";  -- Etat initial
  constant CALC_STATE       : std_logic_vector := "01";
  constant finished_o_STATE   : std_logic_vector := "10";  -- Transitoire

  signal next_state, current_state : std_logic_vector (1 downto 0);

 -- Output signals
  signal iterations_s   : std_logic_vector(SIZE-1 downto 0);
  signal zn1_real_s     : std_logic_vector(SIZE-1 downto 0);
  signal zn1_imag_s     : std_logic_vector(SIZE-1 downto 0);

  -- Intermediate signals
  signal radius_s       : std_logic_vector(2 downto 0); -- on va tester si c'est plus grand que 4, pas besoin de plus
  signal z_real2_s      : std_logic_vector(SIZE-1 downto 0); -- on s'occupe pas du carry
  signal z_imag2_s      : std_logic_vector(SIZE-1 downto 0);
  signal z_r2_i2_s      : std_logic_vector(SIZE-1 downto 0);
  signal z_ri_s         : std_logic_vector(SIZE-1 downto 0);
  
  signal z_real2_big_s      : std_logic_vector(2*SIZE-1 downto 0); -- on s'occupe pas du carry
  signal z_imag2_big_s      : std_logic_vector(2*SIZE-1 downto 0);   
  signal z_ri_big_s         : std_logic_vector(2*SIZE-1 downto 0);
  signal radius_big_s       : std_logic_vector(SIZE-1 downto 0);
  
 

begin
  ----------------------------------------------
  -- calc_proc                         ---------
  ----------------------------------------------
    calc_proc : process (start_i, current_state)
    begin
      next_state <= WAIT_start_i_STATE; --valeur par default
      finished_o <= '0';
      case current_state is
        when WAIT_START_I_STATE =>
          ready_o <= '1';
          if start_i = '1' then
            next_state <= CALC_STATE;
          end if;

        when CALC_STATE  =>
          zn1_real_s <= (others => '0'); -- a zéro comme ça pas de if pour la première itération
          zn1_imag_s <= (others => '0');
          iterations_s <= (others => '0');
          radius_s <= (others => '0');
          while radius_s <= "100" AND unsigned(iterations_s) < max_iter loop
            -- Mise au carré de Zr et Zpi
            z_real2_big_s   <= std_logic_vector(unsigned(zn1_real_s)*unsigned(zn1_real_s));
            z_real2_s       <= z_real2_big_s(comma+SIZE-1 downto comma);
            z_imag2_big_s   <= std_logic_vector(unsigned(zn1_imag_s)*unsigned(zn1_imag_s));
            z_imag2_s       <= z_imag2_big_s(comma+SIZE-1 downto comma);

            -- Soustraction de Zr2 et Zpi2
            z_r2_i2_s       <= std_logic_vector(unsigned(z_real2_s)-unsigned(z_imag2_s));

            -- Multiplication de Zr et Zpi et multiplication par 2
            z_ri_big_s      <= std_logic_vector(unsigned(zn1_real_s)*unsigned(zn1_imag_s));
            z_ri_s          <= z_ri_big_s(comma+SIZE-1 downto comma);
            z_ri_s          <= z_ri_s(SIZE-1 downto 1) & "0"; -- x2

            -- Nouvelle valeur de sortie
            zn1_real_s  <= std_logic_vector(unsigned(z_r2_i2_s)+unsigned(c_real_i));
            zn1_imag_s  <= std_logic_vector(unsigned(z_ri_s)+unsigned(c_imaginary_i));

            radius_big_s    <= std_logic_vector(unsigned(z_real2_s)+unsigned(z_imag2_s));
            radius_s        <= radius_big_s(comma+2 downto comma);

            iterations_s <= std_logic_vector(unsigned(iterations_s) + 1);
          end loop;

          next_state <= finished_o_STATE;
        when finished_o_STATE  =>
          next_state <= WAIT_start_i_STATE;
          finished_o <= '1';
        when others => 
          next_state <= WAIT_start_i_STATE;
        end case;
        
        -- Affectation des sorties
        z_real_o      <= zn1_real_s;
        z_imaginary_o <= zn1_imag_s;
        iterations_o  <= iterations_s;
    end process; -- calc_proc
  ----------------------------------------------
  -- synch_proc                        ---------
  ----------------------------------------------
  	 synch_proc : process (clk_i, rst_i)
     begin
        if (rst_i = '1') then
          current_state <= WAIT_start_i_STATE;
        elsif Rising_Edge(clk_i) then
          current_state <= next_state;
        end if;
    end process; -- synch_proc
end Calculator;
