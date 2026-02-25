# Local Development Setup Guide

## 📋 Overview

This guide explains how to set up your local development environment for the AutoPlanner project using the `develop` branch.

## 🎯 Key Principle

- **`main` branch**: Clean, production-ready code with clear configuration management
- **`develop` branch**: Your development environment - freely test, experiment, and develop
- **Local `.env` file**: Kept in `.gitignore`, contains your personal API keys - never committed

## 🚀 Quick Start (5 minutes)

### 1. Switch to develop branch
```bash
cd /Users/jiaoyan/AutoPlanner
git checkout develop
git pull origin develop
```

### 2. Install dependencies (first time only)
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Initialize database (first time only)
```bash
python manage.py migrate
```

### 4. Get a free Gemini API key
1. Go to [https://ai.google.dev/](https://ai.google.dev/)
2. Click "Get API Key"
3. Create a new project or select an existing one
4. Copy the API key

### 5. Configure local environment
```bash
# Edit .env file and replace the placeholder
nano .env
# Find this line and replace with your actual key:
# GOOGLE_GENERATIVE_AI_KEY=your-free-gemini-api-key-from-ai.google.dev
```

### 6. Run the development server
```bash
source venv/bin/activate
python manage.py runserver
```

✅ Open [http://localhost:8000](http://localhost:8000) in your browser!

## 📂 Project Structure

```
/Users/jiaoyan/AutoPlanner/
├── .env                 ← Your local configuration (in .gitignore)
├── .env.example         ← Template showing required variables
├── db.sqlite3           ← Local development database (auto-created)
├── manage.py            ← Django command-line tool
├── requirements.txt     ← Python dependencies
├── static/              ← CSS, JS, images
├── templates/           ← HTML templates
├── autoplanner/         ← Main Django project settings
├── ai/                  ← AI module (Gemini integration)
├── events/              ← Calendar events module
├── users/               ← User management module
├── caldav_sync/         ← CalDAV synchronization
├── google_sync/         ← Google Calendar sync
└── docs/                ← Documentation
```

## 🛠️ Common Commands

### Run tests
```bash
# All tests
python manage.py test

# Specific app
python manage.py test events
python manage.py test ai
python manage.py test users
```

### Create admin user (optional)
```bash
python manage.py createsuperuser
# Then visit http://localhost:8000/admin/
```

### Database migrations
```bash
# Apply migrations
python manage.py migrate

# Create new migration after model changes
python manage.py makemigrations

# View migration status
python manage.py showmigrations
```

### Static files
```bash
# Collect static files (after Django updates)
python manage.py collectstatic --noinput
```

## 📝 Daily Workflow

### 1. Start your day
```bash
cd /Users/jiaoyan/AutoPlanner
git checkout develop
git pull origin develop
source venv/bin/activate
python manage.py runserver
```

### 2. Develop a new feature
```bash
# Create a new feature branch
git checkout -b feature/my-feature

# Make changes, test locally
# Commit your work
git add .
git commit -m "feat: describe your changes"
git push origin feature/my-feature
```

### 3. Merge to develop when ready
```bash
# Create Pull Request on GitHub, get it reviewed, then:
git checkout develop
git pull origin develop
git merge feature/my-feature
git push origin develop
```

## 🔑 Environment Variables Explained

### Required for development
| Variable | Purpose | Example |
|----------|---------|---------|
| `ENVIRONMENT` | Tells Django we're in development | `development` |
| `DJANGO_DEBUG` | Enables debug mode (error details) | `true` |
| `GOOGLE_GENERATIVE_AI_KEY` | API key for Gemini AI | Your API key from ai.google.dev |

### Optional for calendar features
| Variable | Purpose | Default |
|----------|---------|---------|
| `OAUTHLIB_INSECURE_TRANSPORT` | Allow HTTP in local dev | `true` |
| `GOOGLE_OAUTH_REDIRECT_URI` | OAuth callback URL | `http://localhost:8000/oauth/google/callback` |
| `GOOGLE_OAUTH_CLIENT_JSON_PATH` | Google OAuth credentials file | `./webclient.json` |

## ⚠️ Security Rules

✅ **DO**:
- Keep `.env` file local only (it's in `.gitignore`)
- Use free tier API keys for development
- Change `DJANGO_DEBUG=false` before production

❌ **DON'T**:
- Commit `.env` file to Git
- Share API keys in messages or code
- Push `env-vars.yaml` or `webclient.json` to Git
- Commit real production credentials

## 🐛 Common Troubleshooting

### Issue: `ModuleNotFoundError: No module named 'django'`
**Solution**: Make sure virtual environment is activated
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### Issue: `DJANGO_SECRET_KEY is not set`
**Solution**: Check your `.env` file has `ENVIRONMENT=development`
```bash
grep ENVIRONMENT .env
```

### Issue: Database error
**Solution**: Reset database
```bash
rm db.sqlite3
python manage.py migrate
```

### Issue: Port 8000 already in use
**Solution**: Use a different port
```bash
python manage.py runserver 8001
```

## 📚 More Information

- **Local Testing**: See [README.md](../README.md)
- **Deployment**: See [docs/DEPLOYMENT_GUIDE.md](../docs/DEPLOYMENT_GUIDE.md)
- **Architecture**: See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
- **Common Errors**: See [docs/COMMON_ERRORS.md](../docs/COMMON_ERRORS.md)

## 🎓 Using this on develop branch

The `develop` branch is your safe space for development. You can:
- ✅ Make any changes you want
- ✅ Test new features
- ✅ Break things and fix them
- ✅ Merge to `main` only when verified and tested

Once development is complete and tested, create a Pull Request to merge into `main` for production deployment.

---

**Happy coding! 🚀**
