# AutoPlanner - AI-Powered Schedule Assistant

This is a vibe coding project. It is my first project so the sturcture may not clear. 

------------ AI generated content below this line ------------

A Django-based web application that intelligently parses natural language input and automatically creates events in Google Calendar with one click.

## 🚀 Features

- **Natural Language Parsing**: Convert free-form text into structured calendar events
- **AI-Powered Normalization**: Use Google Gemini API to intelligently understand event details
- **Google Calendar Integration**: Seamlessly sync events with Google Calendar via OAuth 2.0
- **Cloud Deployment**: Running on Google Cloud Run for scalability

## 📋 Quick Links

- **[文档入口](docs/README.md)** - 当前状态与文档导航
- **[手动部署](docs/DEPLOYMENT_SIMPLE.md)** - 唯一有效部署路径
- **[部署策略](DEPLOYMENT_POLICY.md)** - 手动部署与清理规范
- **[系统状态](docs/SYSTEM_STATUS.md)** - 线上版本与运维命令

## 🌐 Live Application

**URL**: https://clickcreate-110580126301.us-west2.run.app
**版本**: V22 (2026-03-03)
**状态**: ✅ 所有功能完全工作（OAuth + AI）

## 🔧 Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start development server
python manage.py runserver 8000

# Run automated tests
python manage.py test
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

For OAuth setup, see [DEPLOYMENT_SIMPLE.md](docs/DEPLOYMENT_SIMPLE.md)

## 📝 License

This project is proprietary.