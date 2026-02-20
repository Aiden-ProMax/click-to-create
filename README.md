# AutoPlanner - AI-Powered Schedule Assistant

This is a vibe coding project. It is my first project so the sturcture may not clear. 

------------ AI generated content below this line ------------

A Django-based web application that intelligently parses natural language input and automatically creates events in Google Calendar with one click.

## 🚀 Features

- **Natural Language Parsing**: Convert free-form text into structured calendar events
- **AI-Powered Normalization**: Use Google Gemini API to intelligently understand event details
- **Google Calendar Integration**: Seamlessly sync events with Google Calendar via OAuth 2.0
- **Cloud Deployment**: Running on Google Cloud Run for scalability
- **Multi-calendar Support**: Support for CalDAV and Google Calendar

## 📋 Quick Links

- **[部署指南](docs/DEPLOYMENT_GUIDE.md)** - Cloud Run 部署步骤
- **[项目结构](docs/PROJECT_STRUCTURE.md)** - 详细的代码结构说明
- **[项目摘要](docs/PROJECT_SUMMARY.md)** - 项目架构和功能总结
- **[完整文档](docs/)** - 所有详细文档

## 🌐 Live Application

**URL**: https://autoplanner-aw36pbwf6a-uc.a.run.app

## 🔧 Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start development server
python manage.py runserver 8000

# Run automated tests
./test_complete.sh
```

## 📦 Technology Stack

- **Backend**: Django 6.0, Django REST Framework
- **Database**: SQLite (dev), PostgreSQL (production)
- **AI**: Google Generative AI (Gemini)
- **Auth**: Google OAuth 2.0
- **Cloud**: Google Cloud Run, Cloud SQL
- **Frontend**: Bootstrap 5, Vanilla JavaScript

## 📧 Configuration

Required environment variables:
- `GOOGLE_GENERATIVE_AI_KEY` - Gemini API key
- `DJANGO_SECRET_KEY` - Django secret key
- `ENVIRONMENT` - 'development' or 'production'

For OAuth setup, see [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

## 📝 License

This project is proprietary.