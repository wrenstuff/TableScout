import os
import smtplib
from dotenv import load_dotenv
from pathlib import Path


env_path = Path(__file__).resolve().parent / "api.env"
load_dotenv(dotenv_path=env_path, override=True)
print("TABLESCOUT_EMAIL loaded:", repr(os.getenv("TABLESCOUT_EMAIL")))


def contact_email(name: str, email: str, subject: str,  message: str):

    gmail_address =os.getenv("TBS_EMAIL")
    gmail_password = os.getenv("TBS_EMAIL_API")
    support_email = os.getenv("TABLESCOUT_EMAIL")

    print("Gmail configured:", bool(gmail_address))
    print("Gmail password configured:", bool(gmail_password))
    print("Recipient configured:", bool(support_email))

    if not gmail_address or not gmail_password or not support_email:
        print("Gmail configuration is missing.")
        return False

    try:
       from email.message import EmailMessage

       msg = EmailMessage()
       msg["From"] = gmail_address
       msg["To"] = support_email
       msg["Reply-To"] = email
       msg ["Subject"] = f"TableScout Contact Form - {subject}"

       msg.set_content(
            f"Name: {name}\n"
            f"Email: {email}\n\n"
            f"Subject: {subject}\n\n"
            f"Message: \n{message}"

       )

       with smtplib.SMTP("smtp.gmail.com", 587) as server:
           server.starttls()
           server.login(gmail_address, gmail_password)
           server.send_message(msg)

           print ("gmail sent successfully")
           return True
    except Exception as error:
        print(f"Email failed to send: {error}")
        return False

def recovery_email(email: str, recovery_code:str):
    gmail_address =os.getenv("TBS_EMAIL")
    gmail_password = os.getenv("TBS_EMAIL_API")
    support_email = os.getenv("TABLESCOUT_EMAIL")

    if not gmail_address or not gmail_password:
        print ('Gmail config incorrect')
        return False

    try:
        from email.message import EmailMessage
        msg =EmailMessage()
        msg["From"] = gmail_address
        msg["To"] = email
        msg["Subject"] = "TableScout Recovery code"
        msg.set_content(
                "Hello,\n\n"
                "We recieved a request to recover your password\n"
                "If this is correct continue by entering the following code into the application. If you did not request this please change your password immediately.\n\n"
                f"Your Verification code is {recovery_code}\n\n"
                "Thanks - Tablescout support"
            )    
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(gmail_address, gmail_password)
            server.send_message(msg)

        print ("recovery code sent successfully!")
        return True
    except Exception as error:
        print(f"Recovery Email failed: {error}")
        return False
