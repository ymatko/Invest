enum 50104 "PTE Broker Transaction Type"
{
    Caption = 'Broker Transaction Type';

    value(0; Buy)
    {
        Caption = 'Buy';
    }
    value(1; Sell)
    {
        Caption = 'Sell';
    }
    value(2; Dividend)
    {
        Caption = 'Dividend';
    }
    value(3; Interest)
    {
        Caption = 'Interest';
    }
    value(4; Fee)
    {
        Caption = 'Fee';
    }
    value(5; Tax)
    {
        Caption = 'Tax';
    }
    value(6; Deposit)
    {
        Caption = 'Deposit';
    }
    value(7; Withdrawal)
    {
        Caption = 'Withdrawal';
    }
    value(8; Other)
    {
        Caption = 'Other';
    }
}