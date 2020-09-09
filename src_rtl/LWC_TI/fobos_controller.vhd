-- fobos_controller.vhd
-- Controller for FOBOS_DUT.vhd, which is DUT-side wrapper in which FOBOS victim implementations are placed
-- fobos_DUT v4
-- William Diehl
-- George Mason University
-- 29 August 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity fobos_controller is
    PORT ( clk, rst : in std_logic;
           load_fifo_finished : in std_logic;
           pdi_start : in std_logic;
           pdi_fifo_empty : in std_logic;
           pdi_ready : in std_logic;
			  rdi_start : in std_logic;
           rdi_fifo_empty : in std_logic;
           rdi_ready : in std_logic;
           sdi_start : in std_logic;
           sdi_fifo_empty : in std_logic;
           sdi_ready : in std_logic;
           do_finished : in std_logic;
           do_fifo_empty : in std_logic;
           is_fifo : in std_logic;
           result_valid : in std_logic;
           do_ready : in std_logic;
           di_valid : in std_logic;
           
           di_ready : out std_logic:='1';
           do_valid : out std_logic;
           result_ready : out std_logic;
           reg_0_en, reg_1_en, reg_2_en, reg_3_en  : out std_logic;
			  do_rd_cnt_en : out std_logic;
			  do_rd_cnt_empty : in std_logic;
			  ld_cnt_full : in std_logic;
			  cmd_en : out std_logic;
 			  fifo_buffer_en : out std_logic;
           load_cntr : out std_logic;
           pdi_fifo_read : out std_logic;
			  fifo_write : out std_logic;
 
			  rdi_fifo_read : out std_logic;
           pdi_valid : out std_logic;
           pdi_cntr_init : out std_logic;
			  rdi_valid : out std_logic;
           rdi_cntr_init : out std_logic;
           sdi_fifo_read : out std_logic;
           sdi_valid : out std_logic;
           sdi_cntr_init : out std_logic;
           do_fifo_write : out std_logic;
           do_fifo_read : out std_logic;
           do_cntr : out std_logic;
           do_cntr_init : out std_logic;
			  ld_cnt_init : out std_logic;
			  rd_cnt_init : out std_logic;
			  rnd_init : out std_logic

          );
end fobos_controller;

architecture behavioral of fobos_controller is
    type state is (IDLE, INSTR0, INSTR1, INSTR2, LOAD_FIFO, REG0, REG1, REG2, REG3, READ_FIFO, READ_FINISH, DUMP, RUN, RESTART);
    signal load_current_state, pdi_current_state, rdi_current_state, sdi_current_state, do_current_state, ready_current_state : state;
    signal load_next_state, pdi_next_state, rdi_next_state, sdi_next_state, do_next_state, ready_next_state : state;
    signal do_done, do_valid_delay, di_ready_ctrl : std_logic:='0';
begin

do_valid <= do_valid_delay; -- currently no delay
di_ready <= di_ready_ctrl;

sync_process: process(clk)

-- synchronous process - updates states at rising edge of clock

begin

IF (rising_edge(clk)) THEN
	if (rst = '1') then
-- this process is currently enabled to function without any input to reset line
-- reset line should be tied to '0' if no intention for synchronous reset
-- asynchronous reset is not supported	
	
		load_current_state <= IDLE; -- idle state
        pdi_current_state <= IDLE;
		  rdi_current_state <= IDLE;
        sdi_current_state <= IDLE;
        do_current_state <= IDLE;
        ready_current_state <= IDLE;
	else
	   load_current_state <= load_next_state;
       pdi_current_state <= pdi_next_state;
		 rdi_current_state <= rdi_next_state;
       sdi_current_state <= sdi_next_state;
       do_current_state <= do_next_state;
       ready_current_state <= ready_next_state;
	END if;
	
  
END IF;

end process;

load_process: process(load_current_state, load_fifo_finished, is_fifo, di_valid, pdi_start, do_done, ld_cnt_full)

-- main FSM of controller; controls the loading of command registers and FIFOs
-- If command register is selected, operation is a two-cycle operation run IDLE to STORE and back to IDLE
-- If FIFO is selected, the operation is multi-cycle and will proceed to READ until FIFO is loaded and then back to IDLE
-- If pdi_start is asserted (check for proper assignment in FOBOS_DUT datapath) then this FSM proceeds to RUN state
-- until the output (DO FIFO) has dumped its contents to the FOBOS Control

begin
	 -- defaults
reg_0_en <= '0';
reg_1_en <= '0';
reg_2_en <= '0';
reg_3_en <= '0';
cmd_en <= '0';
load_cntr <= '0';
fifo_buffer_en <= '0';
fifo_write <= '0';
ld_cnt_init <= '0';
rnd_init <= '0';

case load_current_state is
		 		 
	 when IDLE => 
	    if (pdi_start = '1') then -- Enabled by a "start" command in the command register
	       load_next_state <= RUN; -- proceeds to a RUN state until algorithm completes and DO FIFO empties results
		else if (di_valid = '1') then -- valid register or FIFO address on the bus
					 rnd_init <= '1';
                reg_0_en <= '1'; -- lock address
                --is_fifo_reg <= is_fifo; -- preserve register/FIFO selection for next clock cycle
                load_next_state <= INSTR0;
          
		    else 
			     load_next_state <= IDLE;
			end if;
		end if;
   
	when  INSTR0 => 
		  if (di_valid = '1') then
				reg_1_en <= '1';
				load_next_state <= INSTR1;
		  else
				load_next_state <= INSTR0;
		  end if;
	    
	when  INSTR1 => 
		  if (di_valid = '1') then
				reg_2_en <= '1';
				load_next_state <= INSTR2;
		  else
				load_next_state <= INSTR1;
		  end if;

	when  INSTR2 => 
		  if (di_valid = '1') then
				cmd_en <= '1';
				load_next_state <= REG0;
				
		  else
				load_next_state <= INSTR2;
		  end if;
		  
    when LOAD_FIFO =>
	     if (load_fifo_finished = '1') then
				if (di_valid = '1') then -- valid register or FIFO address on the bus
                reg_0_en <= '1'; -- lock address
                --is_fifo_reg <= is_fifo; -- preserve register/FIFO selection for next clock cycle
                load_next_state <= INSTR0;
				else
					load_next_state <= IDLE;
				end if;
		  else
				if (di_valid = '1') then
					fifo_buffer_en <= '1';
					
					if (ld_cnt_full = '1') then
						ld_cnt_init <= '1';
						fifo_write <= '1';
				   	load_cntr <= '1';
					end if;
				end if;
				load_next_state <= LOAD_FIFO;
		  end if; 

    when REG0 =>
		  if (di_valid = '1') then
				reg_0_en <= '1';
				load_next_state <= REG1;
		  else 
				load_next_state <= REG0;
		  end if;
		  
    when REG1 =>
		  if (di_valid = '1') then
				reg_1_en <= '1';
				load_next_state <= REG2;
		  else 
				load_next_state <= REG1;
		  end if;

    when REG2 =>
		  if (di_valid = '1') then
				reg_2_en <= '1';
				load_next_state <= REG3;
		  else 
				load_next_state <= REG2;
		  end if;

    when REG3 => 
        if (di_valid = '1') then
             reg_3_en <= '1'; -- lock fifo size
				 if (is_fifo = '1') then
					load_next_state <= LOAD_FIFO;
				 else 
				   cmd_en <= '1';
				   load_next_state <= IDLE;
				 end if;
        else 
             load_next_state <= REG3;
        end if;
    
    WHEN RUN => 
        if (do_done = '1') then  -- the do_process FSM will assert do_done when DO FIFO has been dumped
            load_next_state <= IDLE;
        else
            load_next_state <= RUN;
        end if;

	WHEN OTHERS =>
	
		  load_next_state <= IDLE;
			  
	end case; 

END process;


pdi_process: process(pdi_current_state, pdi_start, pdi_fifo_empty, pdi_ready, di_ready_ctrl)

-- this process commences upon pdi_start and feeds the PDI FIFO contents to the victim implementation
-- until it is empty or until victim no longer requests data
--! Caution! If FIFO is starved before victim obtains all PDI data that it expects, the victim could stall indefinitely


begin
	 -- defaults
pdi_fifo_read <= '0';
pdi_valid <= '0';
pdi_cntr_init <= '0';

case pdi_current_state is
		 		 
	 when IDLE => 

	 	if (pdi_start = '1') then
            pdi_fifo_read <= '1'; -- read next word from FIFO
            pdi_next_state <= READ_FIFO;
		else 
			pdi_next_state <= IDLE;
		end if;
    	    
	when READ_FIFO =>
        if (pdi_fifo_empty = '1' or di_ready_ctrl = '1') then
            pdi_cntr_init <= '1';
				pdi_valid <= '1'; -- one cycle delay
            pdi_next_state <= READ_FINISH;
        else 
			   pdi_valid <= '1';
				if (pdi_ready = '1') then
					pdi_fifo_read <= '1';
            end if;
				pdi_next_state <= READ_FIFO;
        end if;
		  
	WHEN READ_FINISH => 
		 -- pdi_valid <= '1';
		  if (di_ready_ctrl = '1') then
		  
			pdi_next_state <= IDLE;
		  else
			pdi_next_state <= READ_FINISH;
			
		  end if;
		  
	WHEN OTHERS =>
	
		  pdi_next_state <= IDLE;
			  
	end case; 

END process;

rdi_process: process(rdi_current_state, rdi_start, rdi_fifo_empty, rdi_ready, di_ready_ctrl)

-- this process commences upon pdi_start and feeds the RDI FIFO contents to the victim implementation
-- until it is empty or until victim no longer requests data
--! Caution! If FIFO is starved before victim obtains all RDI data that it expects, the victim could stall indefinitely


begin
	 -- defaults
rdi_fifo_read <= '0';
rdi_valid <= '0';
rdi_cntr_init <= '0';

case rdi_current_state is
		 		 
	 when IDLE => 

	 	if (rdi_start = '1') then
            rdi_fifo_read <= '1'; -- read next word from FIFO
            rdi_next_state <= READ_FIFO;
		else 
			rdi_next_state <= IDLE;
		end if;
    	    
	when READ_FIFO =>
        if (rdi_fifo_empty = '1' or di_ready_ctrl = '1') then
				rdi_valid <= '1';
            rdi_cntr_init <= '1';
            rdi_next_state <= READ_FINISH;
        else 
			   rdi_valid <= '1';
		      if (rdi_ready = '1') then
					rdi_fifo_read <= '1';
            end if;
				rdi_next_state <= READ_FIFO;
        end if;
 
 	WHEN READ_FINISH => 
		  rdi_valid <= '1';
    	  rdi_next_state <= IDLE;
		  
	WHEN OTHERS =>
	
		  rdi_next_state <= IDLE;
			  
	end case; 

END process;


sdi_process: process(sdi_current_state, sdi_start, sdi_fifo_empty, sdi_ready, di_ready_ctrl)

-- this process commences upon sdi_start and feeds the SDI FIFO contents to the victim implementation
-- until it is empty or until victim no longer requests data
--! Caution! If FIFO is starved before victim obtains all SDI data that it expects, the victim could stall indefinitely

begin
	 -- defaults
sdi_fifo_read <= '0';
sdi_valid <= '0';
sdi_cntr_init <= '0';

case sdi_current_state is
		 		 
	 when IDLE => 

	 	if (sdi_start = '1') then
            sdi_fifo_read <= '1'; -- read next word from FIFO
            sdi_next_state <= READ_FIFO;
		else 
			sdi_next_state <= IDLE;
		end if;
	    
	when READ_FIFO =>
        if (sdi_fifo_empty = '1' or di_ready_ctrl = '1') then
            sdi_cntr_init <= '1';
				sdi_valid <= '1';
            sdi_next_state <= READ_FINISH;
        else
			   sdi_valid <= '1';
            if (sdi_ready = '1') then
					sdi_fifo_read <= '1';
				end if;
            sdi_next_state <= READ_FIFO;
        end if;
        
	WHEN READ_FINISH => 
		  --sdi_valid <= '1';
   	  sdi_next_state <= IDLE;
		  
	WHEN OTHERS =>
	
		  sdi_next_state <= IDLE;
			  
	end case; 

END process;

do_process: process(do_current_state, pdi_start, do_finished, do_fifo_empty, result_valid, do_ready, do_rd_cnt_empty)

-- do_process is in idle until start signal is sent to victim algorithm (pdi_start)
-- when pdi_start is asserted, the do_process waits for a do_finished from the FOBOS_DUT 
-- Then, do_process "dumps" all of the contents of the DO FIFO across the bus to the FOBOS_Controller
-- When empty, it asserts a "do_done" which is a synchronizing signal for the ready_process

begin
	 -- defaults
do_done <= '0';
do_valid_delay <= '0';
result_ready <= '0';
do_fifo_write <= '0';
do_fifo_read <= '0';
do_cntr <= '0';
do_cntr_init <= '0';
do_rd_cnt_en <= '0';
rd_cnt_init <= '0';

case do_current_state is
		 		 
    when IDLE => 
       if (pdi_start = '1') then -- after pdi_start, the FSM starts to look for output from the victim
            do_next_state <= READ_FIFO;
       else
            do_next_state <= IDLE;
       end if;

	when READ_FIFO => 
        if (do_finished = '1') then -- if all expected bytes have been received by FIFO, dump them to control
				do_fifo_read <= '1'; -- delay 1 clock cycle
            do_next_state <= DUMP;
        else
            result_ready <= '1';
            if (result_valid = '1') then -- if valid result on the bus from victim, enqueue to FIFO
                do_fifo_write <= '1';
                do_cntr <= '1';
				end if;
            do_next_state <= READ_FIFO;
         end if;
         
    when DUMP => 
        if (do_ready = '1') then
				if (do_rd_cnt_empty = '1') then
					rd_cnt_init <= '1';
					do_rd_cnt_en <= '1';
					do_valid_delay <= '1';
					if (do_fifo_empty = '1') then
						do_done <= '1';
						do_cntr_init <= '1';
						do_next_state <= IDLE;
					else
						do_fifo_read <= '1';
						do_next_state <= DUMP;
					end if;
				else
				   do_next_state <= DUMP;
					do_rd_cnt_en <= '1';
					do_valid_delay <= '1';
				end if;
			else
				do_next_state <= DUMP;
				do_rd_cnt_en <= '1';
				do_valid_delay <= '1';
			end if;

	WHEN OTHERS =>
	
		  do_next_state <= IDLE;
			  
	end case; 

END process;

ready_process: process(ready_current_state, pdi_start, do_done)

-- asserts di_ready (handshaking signal to FOBOS_CONTROL) until victim  starts
-- deasserts di_ready until victim is done, and all contents of DO FIFO have been sent to FOBOS Control

begin

di_ready_ctrl <= '1';

case ready_current_state is

    when IDLE => 
        if (pdi_start = '1') then
            di_ready_ctrl <= '0';
            ready_next_state <= RUN;
		  else
		      ready_next_state <= IDLE;
        end if;
        
    when RUN => 
        di_ready_ctrl <= '0';
        if (do_done = '1') then
            ready_next_state <= RESTART;
        else
            ready_next_state <= RUN;
        end if;
        
     when RESTART => 
        di_ready_ctrl <= '1';   
        ready_next_state <= IDLE;
        
     when others => 
     
            ready_next_state <= IDLE;
     end case;
end process;        
	
END behavioral;