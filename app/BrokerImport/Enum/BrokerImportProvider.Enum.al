enum 50112 "PTE Broker Import Provider" implements "PTE Broker Report Provider"
{
    value(0; " ")
    {
        Caption = ' ', Locked = true;
        Implementation = "PTE Broker Report Provider" = "PTE Blank Broker Provider";
    }
    value(1; InteractiveBrokers)
    {
        Caption = 'Interactive Brokers', Locked = true;
        Implementation = "PTE Broker Report Provider" = "PTE IBKR Import Provider";
    }
    value(2; Trading212)
    {
        Caption = 'Trading 212', Locked = true;
        Implementation = "PTE Broker Report Provider" = "PTE T212 Import Provider";
    }
}