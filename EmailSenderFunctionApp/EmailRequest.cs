using System.ComponentModel.DataAnnotations;

namespace EmailSenderFunctionApp;

public class EmailRequest
{
    [Required(ErrorMessage = "Email recipient is required")]
    [EmailAddress(ErrorMessage = "Invalid email address format")]
    public string To { get; set; } = string.Empty;

    public string? Subject { get; set; }
    public string? Body { get; set; }
    public bool IsHtml { get; set; }
    public bool SaveToSentItems { get; set; }
}
