# App Behavior Summary: settings.ini and data.db Scenarios

Based on the current implementation, here's how the app reacts to different file combinations:

## File Locations
- **Executable Directory**: Same folder as `mpninfo.exe`
- **settings.ini**: Configuration file in executable directory
- **data.db**: SQLite database file in executable directory

---

## Scenario 1: 🔴 Neither settings.ini nor data.db exist

### App Behavior:
1. **Startup**: App creates default `settings.ini` with SQLite configuration
2. **Login Page**: Shows **"File settings.ini tidak ditemukan"** (red warning)
3. **User Action Required**: Must click settings (⚙️) button to configure database
4. **Database Config Dialog**: 
   - Shows SQLite as default type
   - Shows **"data.db tidak ditemukan"** (orange warning)
   - User can either:
     - Configure MySQL connection, OR
     - Create new SQLite database (app will create data.db)

### Expected User Flow:
```
App Start → Red "settings.ini not found" → Click ⚙️ → Configure DB → Login
```

---

## Scenario 2: 🟡 Only settings.ini exists (no data.db)

### App Behavior:
#### If settings.ini contains **MySQL configuration**:
1. **Login Page**: Shows MySQL connection details (host, port, database, user)
2. **Connection**: Attempts to connect to MySQL server
3. **Result**: Success if MySQL server is accessible, failure otherwise

#### If settings.ini contains **SQLite configuration**:
1. **Login Page**: Shows SQLite configuration details
2. **Database Config Dialog**: Shows **"data.db tidak ditemukan"** warning
3. **Connection**: Will fail until data.db is created or provided

### Expected User Flow:
```
MySQL: App Start → Show MySQL config → Connect → Login
SQLite: App Start → Show SQLite config → Connection fails → Need data.db
```

---

## Scenario 3: 🟡 Only data.db exists (no settings.ini)

### App Behavior:
1. **Startup**: App creates default `settings.ini` with SQLite configuration
2. **Login Page**: Shows SQLite configuration details
3. **Connection**: Successfully connects to existing data.db
4. **Database**: Uses existing tables (no schema creation)

### Expected User Flow:
```
App Start → Create settings.ini → Connect to data.db → Login
```

---

## Scenario 4: 🟢 Both exist + MySQL setup in settings.ini

### App Behavior:
1. **Login Page**: Shows MySQL configuration details:
   ```
   Tipe: MYSQL
   Host: localhost (or configured host)
   Port: 3306 (or configured port)
   User: mpn_user (or configured user)
   Database: mpn_info (or configured name)
   SSL: Enabled/Disabled
   ```
2. **Database**: Completely ignores data.db file
3. **Connection**: Connects to MySQL server using settings
4. **Login**: Works if MySQL credentials are correct

### Expected User Flow:
```
App Start → Show MySQL config → Connect to MySQL → Login
```

---

## Scenario 5: 🟢 Both exist + SQLite setup in settings.ini

### App Behavior:
1. **Login Page**: Shows SQLite configuration details:
   ```
   Tipe: SQLITE
   Database: data.db
   ```
2. **Database**: Uses existing data.db file without creating tables
3. **Connection**: Successfully connects to SQLite
4. **Login**: Works immediately with existing database

### Expected User Flow:
```
App Start → Show SQLite config → Connect to data.db → Login
```

---

## Current Status in Your App

Based on the files in `build/windows/x64/runner/Debug/`:

✅ **settings.ini exists** (332 bytes) with SQLite configuration:
```ini
[Database]
type=sqlite
host=localhost
port=3306
name=mpn_info
username=mpn_user
password=
use_ssl=false
```

✅ **data.db exists** (234,496 bytes) with your prepared database structure

🎯 **Current Scenario**: **Scenario 5** - Both files exist with SQLite setup

---

## Login Page Display

Your login page will now show:
```
┌─────────────────────────────────────┐
│ 🗃️ Database Konfigurasi Saat Ini   │
│ Tipe:     SQLITE                    │
│ Database: mpn_info                  │
└─────────────────────────────────────┘
```

## Database Config Dialog Display

When you click the ⚙️ settings button:
```
┌─────────────────────────────────────┐
│ ✅ data.db ditemukan di:            │
│    D:\...\Debug\data.db             │
│    Menggunakan database yang sudah  │
│    ada (tidak akan membuat tabel    │
│    baru)                            │
└─────────────────────────────────────┘
```

---

## Summary

Your app is now configured for **Scenario 5** and should:
1. ✅ Display SQLite configuration on login page
2. ✅ Connect to your existing data.db file
3. ✅ Use existing database structure (no table creation)
4. ✅ Allow immediate login with correct credentials

The app will work seamlessly with your prepared `data.db` file! 🎉