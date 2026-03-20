namespace EmailSenderFunctionApp.Configuration;

public class EmailConfiguration
{
    public const string SectionName = "EmailSettings";

    public string SenderMailbox { get; set; } = string.Empty;
    public string DefaultSubject { get; set; } = "Notification";
    public bool SaveToSentItems { get; set; }
}
