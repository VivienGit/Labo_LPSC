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
-- 02.03.2018   0.0      VKR      Sequential version
-- 07.03.2018   1.0      VKR      Combinatory version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity mandelbrot_calculator is
generic (
  comma       : integer := 12; 
  max_iter    : integer := 100;
  SIZE        : integer := 16;
  ITER_SIZE   : integer := 7;
  X_ADD_SIZE  : integer := 10;
  Y_ADD_SIZE  : integer := 10);

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
      iterations_o  : out std_logic_vector(ITER_SIZE-1 downto 0);
      x_o           : out std_logic_vector(X_ADD_SIZE-1 downto 0);
      y_o           : out std_logic_vector(Y_ADD_SIZE-1 downto 0);
      x_i           : in std_logic_vector(X_ADD_SIZE-1 downto 0);
      y_i           : in std_logic_vector(Y_ADD_SIZE-1 downto 0)
  );
end mandelbrot_calculator;

architecture Behavioral of mandelbrot_calculator is

  -- Constante pour les tailles (multiplication etc)
  constant SIZE_BIG           : integer := 2*SIZE;
  constant SIZE_IN_BIG        : integer := comma+SIZE;
  constant COMMA_BIG          : integer := 2*comma;
  constant SIZE_RADIUS        : integer := 2*(SIZE-comma);
  constant EXTEND_COMMA       : std_logic_vector(comma-1 downto 0) := (others => '0');      
  
  -- Stat machine states
  constant WAIT_start_i_STATE   : std_logic_vector := "00";  -- Inital state
  constant CALC_STATE           : std_logic_vector := "01";
  constant finished_o_STATE     : std_logic_vector := "10"; 
  signal next_state, current_state : std_logic_vector (1 downto 0);
  
  -- Calculation signals
  signal reset_val            : boolean := false;
  signal calc_finished_s      : boolean := false; 
  signal calc_in_progress     : boolean := false;
  signal iterations_s         : std_logic_vector(ITER_SIZE-1 downto 0) := (others => '0');
  signal z_real_s             : std_logic_vector(SIZE-1 downto 0);
  signal z_imag_s             : std_logic_vector(SIZE-1 downto 0);
  signal zn1_real_s           : std_logic_vector(SIZE-1 downto 0);
  signal zn1_imag_s           : std_logic_vector(SIZE-1 downto 0);
 
  signal z_real2_big_s        : std_logic_vector(SIZE_BIG-1 downto 0);
  signal z_imag2_big_s        : std_logic_vector(SIZE_BIG-1 downto 0);
  signal z_r2_i2_big_s        : std_logic_vector(SIZE_BIG-1 downto 0); 
  signal z_ri_big_s           : std_logic_vector(SIZE_BIG-1 downto 0);
  signal z_2ri_big_s          : std_logic_vector(SIZE_BIG-1 downto 0);  
  signal zn1_real_new_s       : std_logic_vector(SIZE_BIG-1 downto 0);
  signal zn1_imag_new_s       : std_logic_vector(SIZE_BIG-1 downto 0);
  
  signal radius_big_s         : std_logic_vector(SIZE_BIG downto 0);    -- No minus 1, we extend
  signal radius_s             : std_logic_vector(SIZE_RADIUS downto 0); -- same
  

    
begin

  iterations_o    <= iterations_s;
  z_real_o        <= z_real_s;
  z_imaginary_o   <= z_imag_s;
  
  ----------------------------------------------
  --             calc_proc             ---------
  ----------------------------------------------
  calc_proc : process (z_real_s, z_imag_s, zn1_real_s, zn1_imag_s, z_real2_big_s, z_imag2_big_s, radius_big_s, radius_s, z_r2_i2_big_s, z_2ri_big_s, zn1_imag_new_s, c_imaginary_i, c_real_i)
  begin
    -- We only know if its finished later
    calc_finished_s <= false;

    -- At the begining z_real_s and z_imag_s are set to 0
    zn1_real_s <= z_real_s; 
    zn1_imag_s <= z_imag_s;
    
    -- Calcul the squared of the input values   
    z_real2_big_s   <= std_logic_vector(signed(zn1_real_s)*signed(zn1_real_s));
    z_imag2_big_s   <= std_logic_vector(signed(zn1_imag_s)*signed(zn1_imag_s));
          
    -- Calcul the radius to test if we need to stop
    radius_big_s    <= std_logic_vector(signed(z_real2_big_s(SIZE_BIG-1) & z_real2_big_s)+signed(z_imag2_big_s(SIZE_BIG-1) & z_imag2_big_s));
    radius_s        <= std_logic_vector(radius_big_s(SIZE_BIG downto COMMA_BIG));
    
    -- Stop conditions (calcul is finished of the conditions aren't good
    if signed(radius_s) < 4 AND unsigned(iterations_s) < max_iter then
        ----------------- Calcul the real part      --------------------
        -- Substraction of the squared inputs
        z_r2_i2_big_s   <= std_logic_vector(signed(z_real2_big_s)-signed(z_imag2_big_s));
        -- New value of the output (next value of the input)
        zn1_real_new_s  <= std_logic_vector(signed(c_real_i & EXTEND_COMMA) + signed(z_r2_i2_big_s));
        
        ----------------- Calcul the imaginary part  --------------
        -- Multiplication of the two inputs and multiplication by 2
        z_ri_big_s    <= std_logic_vector(signed(zn1_real_s)*signed(zn1_imag_s));
        z_2ri_big_s   <= z_ri_big_s(SIZE_BIG-2 downto 0) & '0'; 
        -- New value of the output (next value of the input)       
        zn1_imag_new_s  <= std_logic_vector(signed(c_imaginary_i & EXTEND_COMMA) + signed(z_2ri_big_s));
          
    else 
        calc_finished_s <= true;
    end if;
      
  end process; -- calc_proc
    
    ----------------------------------------------
     --       Output Buffer and synch           --
    ----------------------------------------------    
    buffer_proc : process (clk_i, rst_i, reset_val, zn1_real_new_s, zn1_imag_new_s, x_i, y_i)
    begin        
        if (rst_i = '1') then
            iterations_s      <= (others => '0'); -- Start the calculation
            z_real_s          <= (others => '0');
            z_imag_s          <= (others => '0');
        elsif reset_val then                 
            iterations_s    <= (others => '0'); -- Start the calculation
            z_real_s        <= (others => '0');
            z_imag_s        <= (others => '0');
        elsif Rising_Edge(clk_i) then
            x_o             <= x_i;
            y_o             <= y_i;
            if not calc_finished_s and calc_in_progress then
                iterations_s    <= std_logic_vector(unsigned(iterations_s) + 1);
                z_real_s        <= zn1_real_new_s(SIZE_IN_BIG-1 downto comma);               
                z_imag_s        <= zn1_imag_new_s(SIZE_IN_BIG-1 downto comma);
            end if;
        end if;
    end process; -- buffer_proc
 
    ----------------------------------------------
    --           State machine                  --
    ----------------------------------------------    
    state_machine : process (current_state, start_i, calc_finished_s)
    begin
        next_state <= WAIT_start_i_STATE;
        finished_o <= '0';
        ready_o <= '0';
        reset_val <= false;
        calc_in_progress <= false;
               
        -- State machine
        case current_state is
            when WAIT_START_I_STATE =>
              ready_o <= '1';
              if start_i = '1' then
                reset_val   <= true;
                next_state  <= CALC_STATE;
              else
                next_state <= WAIT_START_I_STATE;
              end if;
            when CALC_STATE  =>
              if calc_finished_s then
                next_state <= finished_o_STATE;
              else
                calc_in_progress <= true;
                next_state <= CALC_STATE;
              end if;
            when finished_o_STATE  =>
              next_state <= WAIT_start_i_STATE;
              finished_o <= '1';
            when others => 
              next_state <= WAIT_start_i_STATE;
        end case;
    
    end process; -- state_machine
  
    ----------------------------------------------
    --           synch state machine            --
    ----------------------------------------------
  	 synch_proc : process (clk_i, rst_i)
     begin
        if (rst_i = '1') then
          current_state <= WAIT_start_i_STATE;
        elsif Rising_Edge(clk_i) then
          current_state <= next_state;
        end if;
    end process; -- synch_proc
    
end Behavioral;
