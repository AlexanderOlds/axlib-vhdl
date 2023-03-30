library ieee;
  use ieee.std_logic_1164.all;

entity uart_rx is
  generic (
    clk_freq   : integer   := 100_000_000; -- clk frequency (Hz)
    baudrate   : integer   := 115200;      -- datalink baudrate (bits/s)
    osrate     : integer   := 16;          -- oversampling rate (samples/baud period)
    dwidth     : integer   := 8;           -- data width (bits)
    parity     : integer   := 0;           -- parity (0/1 off/on)
    paritytype : std_logic := '0'          -- type of parity (0/1 even/odd)
  );
  port (
    clk     : in    std_logic;
    aresetn : in    std_logic;
    rxbusy  : out   std_logic;
    rxerror : out   std_logic;
    rxdata  : out   std_logic_vector(dwidth - 1 downto 0);
    rx      : in    std_logic
  );
end entity uart_rx;

architecture rtl of uart_rx is

  type rxfsm is (idle, receive);

  signal rxstate     : rxfsm;
  signal baudpulse   : std_logic;
  signal ospulse     : std_logic;
  signal parityerror : std_logic;
  signal rxparity    : std_logic_vector(dwidth downto 0);
  signal rxbuffer    : std_logic_vector((parity + dwidth) downto 0);

begin

  enablepulses : process (clk, aresetn) is

    variable baudcount : integer range 0 to ((clk_freq / baudrate) - 1);
    variable oscount   : integer range 0 to ((clk_freq / baudrate / osrate) - 1);

  begin

    if (aresetn = '0') then
      baudpulse <= '0';
      ospulse   <= '0';
      baudcount := 0;
      oscount   := 0;
    elsif rising_edge(clk) then
      -- baud enable pulse
      if (baudcount < ((clk_freq / baudrate) - 1)) then
        baudcount := baudcount + 1;
        baudpulse <= '0';
      else
        baudcount := 0;
        baudpulse <= '1';
        oscount   := 0; -- reset avoids carry error from freq mismatch
      end if;

      -- oversample enable pulse
      if (oscount < ((clk_freq / baudrate / osrate) - 1)) then
        oscount := oscount + 1;
        ospulse <= '0';
      else
        oscount := 0;
        ospulse <= '1';
      end if;
    end if;

  end process enablepulses;

  receivefsm : process (clk, aresetn) is

    variable oscount : integer range 0 to (osrate - 1);
    variable rxcount : integer range 0 to (parity + dwidth + 2);

  begin

    if (aresetn = '0') then
      oscount := 0;
      rxcount := 0;
      rxbusy  <= '0';
      rxerror <= '0';
      rxdata  <= (others => '0');
      rxstate <= idle;
    elsif (rising_edge(clk) and (ospulse = '1')) then                  -- clock at the oversampling rate

      case rxstate is

        when idle =>

          rxbusy <= '0';
          if (rx = '0') then
            if (oscount < (osrate / 2)) then                           -- not at the center of the start bit
              oscount := oscount + 1;
              rxstate <= idle;
            else
              oscount  := 0;
              rxcount  := 0;
              rxbusy   <= '1';
              rxbuffer <= (rx & rxbuffer((parity + dwidth) downto 1)); -- left shift start bit into buffer
              rxstate  <= receive;
            end if;
          else
            oscount := 0;
            rxstate <= idle;
          end if;

        when receive =>

          if (oscount < (osrate - 1)) then                             -- not at center of bit
            oscount := oscount + 1;
            rxstate <= receive;
          elsif (rxcount < (parity + dwidth)) then                     -- we haven't gotten all bits yet
            oscount  := 0;
            rxcount  := rxcount + 1;
            rxbuffer <= (rx & rxbuffer((parity + dwidth) downto 1));   -- left shift bit into buffer
            rxstate  <= receive;
          else                                                         -- stop bit
            rxdata  <= rxbuffer (dwidth downto 0);
            rxerror <= (rxbuffer(0) or parityerror or not rx);
            rxbusy  <= '0';
            rxstate <= idle;
          end if;

        when others =>

          rxstate <= idle;

      end case;

    end if;

  end process receivefsm;

  rxparitycalc : block is
  begin

    rxparity(0) <= paritytype;

    rxparitylogic : for i in 0 to (dwidth - 1) generate
      rxparity(i + 1) <= rxparity(i) xor rxbuffer(i + 1);
    end generate rxparitylogic;

    with parity select parityerror <=
      (rxparity(dwidth) xor rxbuffer(parity + dwidth)) when 1, -- compare recd and calcd parity
      '0' when others;

  end block rxparitycalc;

end architecture rtl;
