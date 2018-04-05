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
    comma : integer := 12; -- nombre de bits aprÃ¨s la virgule
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

architecture Behavioral of mandelbrot_calculator is

  -- Constante pour les tailles (multiplication etc)
  constant SIZE_BIG             : integer := 2*SIZE;
  constant SIZE_IN_BIG          : integer := comma+SIZE;
  constant COMMA_BIG            : integer := 2*comma;
  constant SIZE_RADIUS          : integer := 2*(SIZE-comma);

  -- Stat machine states
  constant WAIT_start_i_STATE   : std_logic_vector := "00";  -- Etat initial
  constant CALC_STATE           : std_logic_vector := "01";
  constant finished_o_STATE     : std_logic_vector := "10";  -- Transitoire

  signal next_state, current_state : std_logic_vector (1 downto 0);
  
    signal zn1_real_ss     : std_logic_vector(SIZE-1 downto 0);
    signal zn1_imag_ss     : std_logic_vector(SIZE-1 downto 0);

    signal z_real2_big_ss  : std_logic_vector(SIZE_BIG-1 downto 0);  -- Ici pas besoin de retenue
    signal z_imag2_big_ss  : std_logic_vector(SIZE_BIG-1 downto 0);  -- Idem 
    signal z_ri_big_ss     : std_logic_vector(SIZE_BIG-1 downto 0);  -- Idem
    signal z_r2_i2_big_ss  : std_logic_vector(SIZE_BIG downto 0);    -- Pas de moins 1 pour la retenue
    signal radius_big_ss   : std_logic_vector(SIZE_BIG downto 0);    -- idem
    signal radius_ss       : std_logic_vector(SIZE_RADIUS downto 0); -- idem
    
    signal z_2ri_big_ss    : std_logic_vector(SIZE_BIG downto 0);    -- Pas de -1 car on veut garder le signe dans le fois 2
    
    signal zn1_real_big_ss : std_logic_vector(SIZE_BIG+1 downto 0);  -- Plus 1, on a la retenue d'avant plus la nouvelle
    signal zn1_imag_big_ss : std_logic_vector(SIZE_BIG+1 downto 0);  -- idem (1 retenue et fois 2)
    
    signal compl_zn1_ss : std_logic_vector(SIZE_BIG-SIZE downto 0);

begin
  ----------------------------------------------
  -- calc_proc                         ---------
  ----------------------------------------------
    calc_proc : process (start_i, current_state)
    -- Variables de sortie
    variable iterations_s   : std_logic_vector(SIZE-1 downto 0);
    variable zn1_real_s     : std_logic_vector(SIZE-1 downto 0);
    variable zn1_imag_s     : std_logic_vector(SIZE-1 downto 0);
    
    -- Variables intermédiaires
    
    variable z_real2_big_s  : std_logic_vector(SIZE_BIG-1 downto 0);  -- Ici pas besoin de retenue
    variable z_imag2_big_s  : std_logic_vector(SIZE_BIG-1 downto 0);  -- Idem 
    variable z_ri_big_s     : std_logic_vector(SIZE_BIG-1 downto 0);  -- Idem
    variable z_r2_i2_big_s  : std_logic_vector(SIZE_BIG downto 0);    -- Pas de moins 1 pour la retenue
    variable radius_big_s   : std_logic_vector(SIZE_BIG downto 0);    -- idem
    variable radius_s       : std_logic_vector(SIZE_RADIUS downto 0); -- idem
    
    variable z_2ri_big_s    : std_logic_vector(SIZE_BIG downto 0);    -- Pas de -1 car on veut garder le signe dans le fois 2
    
    variable zn1_real_big_s : std_logic_vector(SIZE_BIG+1 downto 0);  -- Plus 1, on a la retenue d'avant plus la nouvelle
    variable zn1_imag_big_s : std_logic_vector(SIZE_BIG+1 downto 0);  -- idem (1 retenue et fois 2)
    
    variable compl_after    : std_logic_vector(comma-1 downto 0) := (others => '0');     -- Pour compléter les inputs
    variable compl_before   : std_logic_vector(SIZE-comma downto 0);
    
    variable stop_calc      : boolean := false;
    
    begin
      --valeurs par default
      next_state <= WAIT_start_i_STATE;
      finished_o <= '0';
      ready_o <= '0';
      
      -- State machine
      case current_state is
        when WAIT_START_I_STATE =>
          ready_o <= '1';
          if start_i = '1' then
            next_state <= CALC_STATE;
          end if;

        when CALC_STATE  =>
          -- On met à zéro car à la première itération Z0 = 0 !!       
          zn1_real_s := (others => '0'); 
          zn1_imag_s := (others => '0');
          
          iterations_s := (others => '0');
          
          -- On calcul tant que le carré du rayon n'est pas plus grand que 4 ou qu'on arrive à max_iter
          while not stop_calc loop
            -- Mise au carré de Zr et Zpi
            z_real2_big_s   := std_logic_vector(signed(zn1_real_s)*signed(zn1_real_s));
            z_imag2_big_s   := std_logic_vector(signed(zn1_imag_s)*signed(zn1_imag_s));
            
            -- Calcul du rayon
            radius_big_s    := std_logic_vector(unsigned('0' & z_real2_big_s)+unsigned('0' & z_imag2_big_s)); -- C'est des carrés, c'est forcément positif
            radius_s        := std_logic_vector(radius_big_s(SIZE_BIG downto COMMA_BIG));

            -- Condition de sortie
            if unsigned(radius_s) <= 4  AND unsigned(iterations_s) < 1 then
            ----------------- Calcul de la partie reel --------------------
                -- Soustraction de Zr2 et Zpi2
                z_r2_i2_big_s   := std_logic_vector(signed('0' & z_real2_big_s)-signed('0' & z_imag2_big_s));
                
                -- Avant de couper pour garder un vecteur de la taille de CR pour l'addition qui va suivre, on regarde ce qu'on va enlever au dessus
                -- On doit traiter pour garder un chiffre représentatif (pas enlever 32 par exemeple parce qu'il était sur le bit 5 qu'on garde pas)
                -- On regarde les 5 au dessus (4 + retenue) et aussi le premier bit que l'on va garder sinon ça peut changer de signe
                -- Si c'est que des 0 ou que des 1 c'est le chiffre sera le même après troncation
                
                compl_before        := (others => c_real_i(SIZE-1));
                zn1_real_big_s      := std_logic_vector(signed(z_r2_i2_big_s(SIZE_BIG) & z_r2_i2_big_s)+signed(compl_before & c_real_i & compl_after));
 
                if zn1_real_big_s(SIZE_BIG+1 downto SIZE_IN_BIG-1) = "0000000" OR zn1_real_big_s(SIZE_BIG+1 downto SIZE_IN_BIG-1) = "1111111" then
                    zn1_real_s   := zn1_real_big_s(SIZE_IN_BIG-1 downto comma);
                --Sinon si c'est un entier positif plus grand que 4 donc on met tout à 1 sauf le premier 
                elsif zn1_real_big_s(SIZE_BIG+1) = '0' then
                    zn1_real_s   := "0111" & "111111111111";
                -- Sinon c'est que le premeir valait 1 et les autres pas donc c'est un négatif supérieur à 4
                else
                    zn1_real_s   := "1000" & "000000000000";
                end if;
                
              ----------------- Calcul de la partie imaginaire --------------------  
                -- Multiplication de Zr et Zpi et multiplication par 2
                z_ri_big_s      := std_logic_vector(signed(zn1_real_s)*signed(zn1_imag_s));
                z_2ri_big_s     := z_ri_big_s & '0';
                
                compl_before        := (others => c_imaginary_i(SIZE-1));
                zn1_imag_big_s      := std_logic_vector(signed(z_2ri_big_s(SIZE_BIG) & z_2ri_big_s)+signed(compl_before & c_imaginary_i & compl_after)); 
                
                if zn1_imag_big_s(SIZE_BIG+1 downto SIZE_IN_BIG-1) = "0000000" OR zn1_imag_big_s(SIZE_BIG+1 downto SIZE_IN_BIG-1) = "1111111" then
                    zn1_imag_s   := zn1_imag_big_s(SIZE_IN_BIG-1 downto comma);
                --Sinon si c'est un entier positif plus grand que 4 donc on met tout à 1 sauf le premier 
                elsif zn1_imag_big_s(SIZE_BIG+1) = '0' then
                    zn1_imag_s   := "0111" & "111111111111";
                -- Sinon c'est que le premeir valait 1 et les autres pas donc c'est un négatif supérieur à 4
                else
                    zn1_imag_s   := "1000" & "000000000000";
                end if;

                -- incrémentation du compteur
                iterations_s := std_logic_vector(unsigned(iterations_s) + 1);
             else 
                stop_calc := true;
             end if;
          end loop;
          
          stop_calc := false;

          next_state <= finished_o_STATE;
        when finished_o_STATE  =>
          next_state <= WAIT_start_i_STATE;
          finished_o <= '1';
        when others => 
          next_state <= WAIT_start_i_STATE;
        end case;
        
        -- Pour le debug
        zn1_real_ss <= zn1_real_s; 
        zn1_imag_ss <= zn1_imag_s;
        z_real2_big_ss <= z_real2_big_s;
        z_imag2_big_ss <= z_imag2_big_s;
        z_ri_big_ss <= z_ri_big_s;
        z_r2_i2_big_ss <=z_r2_i2_big_s;
        radius_big_ss <= radius_big_s;
        radius_ss  <=   radius_s;
        
        z_2ri_big_ss  <= z_2ri_big_s;
        
        zn1_real_big_ss <= zn1_real_big_s;
        zn1_imag_big_ss <= zn1_imag_big_s;
        
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
end Behavioral;
