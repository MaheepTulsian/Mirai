# Adding Sample Data to Firestore

## Method 1: Firebase Console (Quick & Easy)

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **Firestore Database** in the left menu

### Step 2: Add Jobs Collection

1. Click **"Start collection"** (or "Add collection" if you have other collections)
2. Collection ID: `jobs`
3. Click **Next**
4. Add first document:
   - Document ID: (leave auto-generated)
   - Add fields:
     ```
     title (string): "Backend Developer - Freshers"
     company (string): "Tech Solutions Inc"
     location (string): "Bangalore, India"
     description (string): "Join our team as a Backend Developer..."
     tags (array): ["backend", "nodejs", "mongodb", "fresher"]
     logo (string): "https://via.placeholder.com/150"
     link (string): "https://example.com/apply"
     postedDate (number): 1735467890123
     isActive (boolean): true
     ```
5. Click **Save**
6. Repeat for 2-3 more jobs

### Step 3: Add Internships Collection

1. Click **"Start collection"**
2. Collection ID: `internships`
3. Add documents with fields:
   ```
   title (string): "Web Development Intern"
   company (string): "Tech Startup"
   location (string): "Pune, India"
   description (string): "Learn React, Node.js..."
   tags (array): ["internship", "web", "react", "paid"]
   logo (string): "https://via.placeholder.com/150"
   link (string): "https://example.com/apply"
   postedDate (number): 1735467890123
   isActive (boolean): true
   ```

### Step 4: Add Courses Collection

1. Click **"Start collection"**
2. Collection ID: `courses`
3. Add documents with fields:
   ```
   title (string): "Complete Web Development Bootcamp 2024"
   platform (string): "Udemy"
   instructor (string): "Angela Yu"
   description (string): "Master HTML, CSS, JavaScript..."
   level (string): "beginner"
   duration (string): "52 hours"
   price (number): 499
   originalPrice (number): 4999
   tags (array): ["web-development", "fullstack", "javascript"]
   logo (string): "https://via.placeholder.com/300x200"
   enrollLink (string): "https://udemy.com/course/example"
   rating (number): 4.7
   isActive (boolean): true
   ```

### Step 5: Add Roadmaps Collection

1. Click **"Start collection"**
2. Collection ID: `roadmaps`
3. Add documents with fields:
   ```
   name (string): "Frontend Developer Roadmap 2024"
   description (string): "Complete path to becoming..."
   category (string): "Web Development"
   difficulty (string): "Beginner to Advanced"
   estimatedTime (string): "6-12 months"
   tags (array): ["frontend", "web-development", "career"]
   imageUrl (string): "https://via.placeholder.com/400x300"
   steps (array): [
     {
       title: "HTML & CSS Fundamentals",
       description: "Learn the building blocks...",
       resources: []
     }
   ]
   isActive (boolean): true
   ```

### Step 6: Add Guide Collection

1. Click **"Start collection"**
2. Collection ID: `guide`
3. Add documents with fields:
   ```
   name (string): "Getting Started with Git & GitHub"
   description (string): "Complete guide to version control"
   category (string): "Development Tools"
   tags (array): ["git", "github", "version-control"]
   content (string): "Learn Git basics, branching..."
   isActive (boolean): true
   ```

---

## Method 2: Using Firestore REST API (Bulk Import)

### Using curl to add data:

```bash
# Set your Firebase project ID
PROJECT_ID="mirai2026"

# Add a job
curl -X POST \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/jobs" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "title": {"stringValue": "Backend Developer - Freshers"},
      "company": {"stringValue": "Tech Solutions Inc"},
      "location": {"stringValue": "Bangalore, India"},
      "description": {"stringValue": "Join our team as a Backend Developer..."},
      "tags": {"arrayValue": {"values": [
        {"stringValue": "backend"},
        {"stringValue": "nodejs"}
      ]}},
      "logo": {"stringValue": "https://via.placeholder.com/150"},
      "link": {"stringValue": "https://example.com/apply"},
      "postedDate": {"integerValue": "1735467890123"},
      "isActive": {"booleanValue": true}
    }
  }'
```

---

## Method 3: Quick Test Data (Minimal)

Add just 1 document per collection to test:

### Jobs
```
Collection: jobs
Document ID: (auto)
Fields:
- title: "Backend Developer"
- company: "Tech Corp"
- location: "Bangalore"
- description: "Backend role"
- tags: ["backend"]
- logo: "https://via.placeholder.com/150"
- link: "https://example.com"
- postedDate: 1735467890123
- isActive: true
```

### Internships
```
Collection: internships
Document ID: (auto)
Fields:
- title: "Web Dev Intern"
- company: "Startup"
- location: "Remote"
- description: "Intern role"
- tags: ["internship"]
- logo: "https://via.placeholder.com/150"
- link: "https://example.com"
- postedDate: 1735467890123
- isActive: true
```

### Courses
```
Collection: courses
Document ID: (auto)
Fields:
- title: "Web Development Course"
- platform: "Udemy"
- instructor: "John Doe"
- description: "Learn web dev"
- level: "beginner"
- duration: "20 hours"
- price: 499
- originalPrice: 2999
- tags: ["web"]
- logo: "https://via.placeholder.com/300x200"
- enrollLink: "https://example.com"
- rating: 4.5
- isActive: true
```

### Roadmaps
```
Collection: roadmaps
Document ID: (auto)
Fields:
- name: "Frontend Roadmap"
- description: "Learn frontend"
- category: "Web Development"
- difficulty: "Beginner"
- estimatedTime: "6 months"
- tags: ["frontend"]
- imageUrl: "https://via.placeholder.com/400x300"
- steps: []
- isActive: true
```

### Guide
```
Collection: guide
Document ID: (auto)
Fields:
- name: "Git Guide"
- description: "Learn Git"
- category: "Tools"
- tags: ["git"]
- content: "Git basics..."
- isActive: true
```

---

## Verify Data

1. Open your app (flutter run)
2. Navigate to each tab (Jobs, Internships, Courses, Roadmaps)
3. You should see the sample data displayed

---

## Production Data

For production, replace placeholder data with:
- Real job listings from job boards
- Actual internship opportunities
- Verified course links
- Curated learning roadmaps
- Quality guides

Consider using:
- Web scraping (with permission)
- Partnerships with job boards
- Manual curation
- User submissions (with moderation)
