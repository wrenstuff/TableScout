async def handle_contact(data):
    email = data.get("email")
    subject = data.get("subject")
    message = data.get("message")

    if not all(isinstance(value, str) and value.strip() for value in [email, subject, message]):
        return {
            "type": "error",
            "success": False,
            "message": "All fields (email, subject, message) are required."
        }

    if len(email)> 254:
        return {
            "type": "error",
            "success": False,
            "message": "Email is too long."
        }

    if len(subject) > 200:
        return {
            "type": "error",
            "success": False,
            "message": "Subject is too long."
        }

    if len(message) > 1000:
        return {
            "type": "error",
            "success": False,
            "message": "Message is too long."
        }

    
    return {
        "type": "contact_response",
        "success": True,
        "message": "Contact form submitted successfully."
    }