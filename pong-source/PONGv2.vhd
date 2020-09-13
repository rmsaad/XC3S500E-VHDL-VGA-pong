library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USe IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity PONGv2 is
	Port ( 
	clk		: in STD_LOGIC;
	H			: out STD_LOGIC;
	V			: out STD_LOGIC;
	DAC_CLK	: out STD_LOGIC;
	Rout		: out STD_LOGIC_VECTOR(7 downto 0);
	Gout		: out STD_LOGIC_VECTOR(7 downto 0);
	Bout		: out STD_LOGIC_VECTOR(7 downto 0);
	SW0		: in STD_LOGIC;
	SW1		: in STD_LOGIC;
	SW2		: in STD_LOGIC;
	SW3		: in STD_LOGIC;
	BTNL		: in STD_LOGIC;
	BTNR 		: in STD_LOGIC;
	BTNU		: in STD_LOGIC;
	BTND 		: in STD_LOGIC 	
	);
end PONGv2;


architecture Behavioral of PONGv2 is
-- BASIC SIGNALS
signal dclk : std_logic;
signal hsync, vsync, delay : Integer := 0;
signal h_pos : integer range 0 to 640;
signal v_pos : integer range 0 to 480;
signal p1, p2 : Integer := 158;
signal ball_x  : Integer :=312;
signal ball_y : Integer := 232;
signal ball_xmove, ball_ymove : Integer := 4;

-- SIZINGS
signal buttoncounter : Integer range 0 to 50 :=0;
signal ballmovespeed : Integer := 4;
signal playermovespeed : Integer := 3;
signal paddlewidth : Integer := 50;
constant nettop : Integer := 126;
constant netbottom : Integer := 484-nettop;--  358;

signal score : Integer range -160 to 160 :=0;
signal score_x : Integer := 312;

BEGIN
--Half Clock Time
PROCESS (clk)
BEGIN
	IF (rising_edge(clk)) THEN
		IF (dclk = '1') THEN
			dclk <= '0';
		ELSE
			dclk <= '1';
		END IF;
	END IF;
END PROCESS;
DAC_CLK <= dclk;
PROCESS(dclk)
BEGIN
-- Syncing
IF (rising_edge(dclk)) THEN
	IF (hsync = 800) THEN
		vsync <= vsync + 1;
		hsync <= 0;
	ELSE
		hsync <= hsync + 1;
	END IF;	
	IF (vsync = 524) THEN
		vsync <= 0;
	END IF;
	-- SyncPulse 64
	IF (hsync >= 656 AND hsync <= 751) THEN
		H <= '0'; 
	ELSE
		H <= '1';
	END IF;
	-- SyncPulse
	IF (vsync >= 490 AND vsync <= 491) THEN
		V <= '0'; 
	ELSE
		V <= '1'; 
	END IF;
END IF;
END PROCESS;

-- Static
PROCESS (dclk, hsync, vsync)
BEGIN
IF (rising_edge(dclk)) THEN

			h_pos<=hsync;
			v_pos<=vsync;
				-- BACKGROUND COLOURING
				
			--White top/bottom border	
			if(h_pos >= 25 and h_pos <= 615 and ((v_pos >= 25 and v_pos <= 36) or (v_pos >= 448 and v_pos <= 459)))then
					ROUT<="10101101";
					GOUT<="10101101";
					BOUT<="10101101";  
			--White sides border
			elsif(((h_pos >= 25 and h_pos <= 36) or (h_pos >= 604 and h_pos <= 615)) and ((v_pos >= 36 and v_pos <= nettop) or(v_pos >= netbottom and v_pos <= 448)))then
					ROUT <= "10101101";		
					GOUT <= "10101101";
					BOUT <= "10101101";  
			-- Middle grey lines
			elsif((h_pos > 316 and h_pos < 324) and v_pos >= 37 and v_pos < 448) and (((v_pos - 35) mod 64) > 32) then
					ROUT<="00010010";
					GOUT<="00010010";
					BOUT<="00010010";
			-- all else green					
			elsif(h_pos>0 and h_pos<640 and v_pos>0 and v_pos<480)then
					ROUT <= "00000000";		
					GOUT <= "01010111";
					BOUT <= "00000000"; 
			else
					ROUT <= (OTHERS => '0');		
					GOUT <= (OTHERS => '0');
					BOUT <= (OTHERS => '0');
			end if;	
	
	-- Colour Player 1 (Blue paddle)
	if(hsync > 45 AND hsync <=59 AND vsync> p1 AND vsync<= p1 + paddlewidth) THEN
		ROUT <= "00000000";
		GOUT <= "00000000";
		BOUT <= "10101101";
		
	-- Colour Player 2 (Pink Paddle)
	elsif(hsync > 581 AND hsync <=595 AND vsync> p2 AND vsync<= p2 + paddlewidth) THEN
		ROUT <= "10101101";
		GOUT <= "00000000";
		BOUT <= "10101101";
	
	elsif (hsync > (score_x+score) and hsync <= (score_x+16+score)) and vsync>4 and vsync<=20 then
			ROUT <= "10101101";
			GOUT <= "01010111";
			BOUT <= "00000000";
		
	-- Colour Ball
	elsif(hsync > ball_x AND hsync <= ball_x+16 AND vsync>ball_y AND vsync<=(ball_y+16)) THEN
		if(ball_x <= 12 OR ball_x+16 >= 628) THEN

			-- Red, Net contact
			ROUT <= "10101101";
			GOUT <= "00000000";
			BOUT <= "00000000";
			if(delay = 6000) THEN
				if ball_x<= 12 then
					score <= score - 16;
				else 
					score <= score + 16;
				end if;
				if (score = 160 or score = -160) then
					score <= 0;
				end if;
				ball_x <= 312;
				delay <= 0;
				ball_xmove <= -ball_xmove;
				ball_ymove <= -ball_ymove;
			else
				delay <= delay + 1;
			end if;
		else
			ROUT <= "10101101";
			GOUT <= "10101101";
			BOUT <= "00000000";
		end if;
	
	END IF;
	
	if(hsync = 639 AND vsync = 479)THEN
		
		-- BALL HIT DETECTION
			--Walls
		if(ball_x <= 36 OR ball_x+16 >= 604) THEN
			if(ball_y > nettop AND ball_y < netbottom) THEN

			else
				if(ball_x <= 36) THEN
					ball_xmove <= ballmovespeed;
				else
					ball_xmove <= -ballmovespeed;
				end if;
			end if;
		end if;
		
			--Bottom and top
		if(ball_y <= 36) THEN
			ball_ymove <= ballmovespeed;
		end if;
		if(ball_y+16 >= 448) THEN
			ball_ymove <= -ballmovespeed;
		end if;
		
			--Player1
		if((ball_x <= 60 AND ball_x+16 >=44) AND (ball_y+16 > p1 AND ball_y < p1+paddlewidth)) THEN
			ball_xmove <= ballmovespeed;
		end if;
		
		 -- Player2
		if((ball_x<=597 AND ball_x+16 >= 581) AND(ball_y+16 > p2 AND ball_y < p2+paddlewidth)) THEN
			ball_xmove <= -ballmovespeed;
		end if;
		
		-- move player 1
		if (SW1 = '1') then		
			if (SW0 = '1' AND p1 >= 43) then 
				p1 <= p1 - playermovespeed;
			elsif (SW0 = '0' AND p1 + paddlewidth <= 440) then  
				p1 <= p1 + playermovespeed;
			end if;
		end if;
		
		-- Move Player 2
		if (SW3 = '1') then		
			if (SW2 = '1' AND p2 >= 43) then 
				p2 <= p2 - playermovespeed;
			elsif (SW2 = '0' AND p2 + paddlewidth <= 440) then  
				p2 <= p2 + playermovespeed;
			end if;
		end if;
		
		-- Move Ball if not in Net
		if(NOT(ball_x <= 10 OR ball_x+16 >= 630)) THEN
			ball_x <= ball_x + ball_xmove;
			ball_y <= ball_y + ball_ymove;
		end if;
		
		if buttoncounter /= 0 then 
				buttoncounter <= buttoncounter +1;
		end if;
			
--			--SPEED CONTROL
		if (BTNL = '1' and buttoncounter = 0 and playermovespeed > 1) then
			buttoncounter <= buttoncounter+1;
			playermovespeed <= playermovespeed -1;
			ballmovespeed <= ballmovespeed -1;
   	end if;
		if (BTNR = '1' and buttoncounter = 0 and playermovespeed < 15) then
			buttoncounter <= buttoncounter;
			playermovespeed <= playermovespeed;
			ballmovespeed <= ballmovespeed;
		end if;
		
			-- SIZE CONTROL
		if (BTNU = '1' and buttoncounter = 0 and paddlewidth < 300) then
			buttoncounter <= buttoncounter+1;
				paddlewidth <= paddlewidth +5;
		end if;
		if (BTND = '1' and buttoncounter = 0 and paddlewidth >5) then
			buttoncounter <= buttoncounter+1;
			paddlewidth <= paddlewidth -5;
		end if;
	end if;
End IF;
END PROCESS;	
end Behavioral;
