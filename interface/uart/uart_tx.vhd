
library ieee;
  use ieee.std_logic_1164.all;

entity uart_tx is
  generic (
    clk_freq   : integer   := 100_000_000; -- clk frequency (Hz)
    baudrate   : integer   := 115200;      -- datalink baudrate (bits/s)
    osrate     : integer   := 16;          -- oversampling rate (samples/baud period)
    dwidth     : integer   := 8;           -- data width (bits)
    parity     : integer   := 0;           -- parity (0/1 off/on)
    paritytype : std_logic := '0'          -- type of parity (0/1 even/odd)
  );
  port (
    clk      : in    std_logic;
    aresetn  : in    std_logic;
    txenable : in    std_logic;
    txdata   : in    std_logic_vector(dwidth - 1 downto 0);
    txbusy   : out   std_logic;

    tx : out   std_logic
  );
end entity uart_tx;

architecture rtl of uart_tx is

  type txfsm is (idle, transmit);

  signal txstate   : txfsm;
  signal baudpulse : std_logic;
  signal ospulse   : std_logic;
  signal txparity  : std_logic_vector(dwidth downto 0);
  signal txbuffer  : std_logic_vector((parity + dwidth + 1) downto 0);

begin

  transmitfsm : process (clk, aresetn) is

    variable txcount : integer range 0 to (parity + dwidth + 3);

  begin

    if (aresetn = '0') then
      txcount := 0;
      tx      <= '1';
      txbusy  <= '1';
      txstate <= idle;
    elsif rising_edge(clk) then

      case txstate is

        when idle =>

          if (txenable = '1') then
            txbuffer((dwidth + 1) downto 0) <= (txdata & '0' & '1');  -- latch in data, start, and stop
            if (parity = 1) then
              txbuffer(parity + dwidth + 1) <= txparity(dwidth);      -- latch in parity bit;
            end if;
            txbusy  <= '1';
            txcount := 0;
            txstate <= transmit;
          else
            txbusy  <= '0';
            txstate <= idle;
          end if;

        when transmit =>

          if (baudpulse = '1') then
            txcount  := txcount + 1;
            txbuffer <= ('1' & txbuffer((parity + dwidth) downto 1)); -- shift buffer to next bit
          end if;
          if (txcount < (parity + dwidth + 3)) then
            txstate <= transmit;
          else                                                        -- all bits transmitted
            txstate <= idle;
          end if;

        when others =>

          txstate <= idle;

      end case;

      tx <= txbuffer(0);                                              -- drive output
    end if;

  end process transmitfsm;

  txparitycalc : block is
  begin

    txparity(0) <= paritytype;

    txparitylogic : for i in 0 to (dwidth - 1) generate
      txparity(i + 1) <= txparity(i) xor txdata(i);
    end generate txparitylogic;

  end block txparitycalc;

end architecture rtl;
