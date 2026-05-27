codeunit 50114 "PTE Blank Broker Provider" implements "PTE Broker Report Provider"
{
    procedure Import(Broker: Record "PTE Broker"; SourceFileName: Text; var SourceInStream: InStream; var ImportHeader: Record "PTE Broker Import Header")
    begin
        Error(ImportProviderNotSelectedErr);
    end;

    var
        ImportProviderNotSelectedErr: Label 'Import provider is not selected for the broker.';
}