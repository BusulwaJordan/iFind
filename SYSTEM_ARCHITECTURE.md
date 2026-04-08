# iFind System Architecture & Technical Documentation

## 1. System Overview

iFind is an AI-powered local business connection ecosystem built explicitly for emerging markets like Uganda. It operates as a dual-sided platform (B2C and B2B), bridging the digital divide for SMEs. 

Unlike generic directories, iFind utilizes a **Hybrid AI Recommendation Engine**. It performs high-speed geometric math (via PostgreSQL PostGIS) to find physical locations near a user, and then pipes that contextual local data directly into a Large Language Model (Google Gemini AI) to provide highly personalized matchmaking based on the user's natural language intent.

## 2. Core Technologies

- **Frontend Application:** Flutter (Dart) using Material 3. Handles cross-platform mobile compilation (Android/iOS).
- **State Management:** Riverpod 2.x (with code generation) to decouple business logic from UI securely.
- **Backend Infrastructure:** Supabase Serverless Platform.
  - **Database:** PostgreSQL (with `uuid-ossp` and `postgis` extensions).
  - **Authentication:** Supabase Auth (Email, Social, and Role-based JWTs).
  - **Storage:** Supabase Storage for business covers, logos, and chat assets.
- **AI / LLM Integration:** Google Generative AI (`gemini-pro`).
- **Geomatics / Mapping:** OpenStreetMap with `flutter_map` and PostgreSQL `ST_DWithin` functions.

---

## 3. Data Architecture (PostgreSQL + PostGIS)

iFind's database schema relies heavily on **Row Level Security (RLS)** to enforce multi-tenant operations securely. 

### Key Entities
*   `users`: Categorized rigidly by `role` (`customer`, `business_owner`, `manager`). Profile data bound to Supabase Auth UUIDs.
*   `businesses`: Uses PostGIS `GEOGRAPHY(POINT, 4326)` for precise plotting. Contains verification states (`pending`, `verified`, `rejected`) and pre-calculated average ratings.
*   `arcades` & `shops`: Represents digital container structures allowing a single primary business (an Arcade) to host multiple independently managed shops (virtual marketplace).
*   `products`: Tied to either an individual shop or a standalone business.
*   `chats` & `messages`: High-speed message records bridging customers directly to business owners or B2B channels.

### Proximity Resolution (Geospatial RPC)
In order to rapidly filter out irrelevant regions out of millions of rows, iFind uses a remote procedure call (RPC) macro via Supabase called `get_nearby_businesses`.
```sql
ST_DWithin(
    location, 
    ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography, 
    radius_meters
)
```
This forces PostgreSQL to rely on its incredibly efficient `GiST` spatial index to calculate bounding boxes before performing exact metric distances.

---

## 4. Frontend Application Architecture (Clean Architecture)

The Flutter codebase is modular, split strictly by Feature over Layer. 

### Folder Structure
```
lib/
├── core/                   # 1. Core
│   ├── errors/             # Failure models and Exception parsing
│   ├── services/           # External boundaries (e.g. ai_service.dart)
│   ├── router/             # GoRouter configuration
│   └── constants/          # Colors, Configs, .env loaders
│
├── features/               # 2. Functional Modules
│   ├── auth/
│   ├── business/
│   ├── discovery/          # PostGIS location fetching
│   ├── recommendations/    # AI match-making orchestration
│   └── chat/               
```

### Flow of Data (The Feature Slice)
Every feature executes data through four layers to maintain testability and low coupling:
1.  **Remote Data Source:** Makes the actual HTTP/Supabase queries (e.g. `ai_recommendation_datasource.dart`).
2.  **Repository Implementation:** Handles failures, caching, and maps external data models to pure Dart Entities.
3.  **Entity (Domain):** The pure Dart objects (e.g., `business.dart`, `recommendation.dart`) completely unaware of Supabase or JSON.
4.  **Presentation / Provider:** UI state consumed via Riverpod. E.g., `aiMatchmakingProvider` watches the Repository and feeds `AsyncValue<List<Recommendation>>` straight into the UI.

---

## 5. The Hybrid AI Matchmaking Engine

This is the central nervous system differentiating iFind from competitors. It resolves standard NLP inefficiencies by using context-aware limits.

**How it works sequentially:**
1.  **User Input:** The user types a natural language intent (e.g., "Where can I fix my broken phone screen?") locally.
2.  **Geospatial Pre-Filtering:** The `DiscoveryRemoteDataSource` runs a PostGIS radius check (e.g. 5 kilometers) and retrieves 20 verified local businesses. The UI filters out the rest of the country natively, preventing the AI from hallucinating a business in a different city.
3.  **JSON Packing:** The application bundles the user intent and the 20 local business profiles into an optimized JSON context string.
4.  **Generative AI Analysis:** The `AiService` sends this optimized payload to Gemini via `google_generative_ai`. A strict system prompt forces the LLM to cross-reference the user intent against the local JSON manifest.
5.  **Output Parsing:** The application parses Gemini's response resulting in an ordered array of `Recommendation` entities containing logic (e.g., "John's Electronics is 1.2km away and explicitly lists screen repairs in their services").

---

## 6. Scaling and Operational Guidelines

### Infrastructure Scaling (PostgreSQL)
Because the heavy lifting is completely off-loaded to PostGIS and Google Gemini, the node app/backend does not experience OOM (Out of Memory) conditions under high concurrency. 
- Ensure `location` indices (`CREATE INDEX idx_businesses_location ON businesses USING GIST(location);`) remain rebuilt dynamically over time.
- Move real-time listeners (for `chats`) specifically into Supabase Realtime Channels to minimize standard HTTP polling.

### Low-Bandwidth Optimizations
For the Ugandan operating context:
- Avoid returning `cover_image_url` data during the AI scanning phase to keep payloads <10KB.
- Use `flutter_image_compress` locally to enforce image resolutions below 800px globally before sending assets to Supabase Storage. Avoid allowing uncompressed 4K phone shots into the DB.

### Future Roadmap (Next Steps)
1.  **Offline Access (Cache):** Utilize `shared_preferences` or `sqflite` at the Repository level to cache recent chat data and homepage business clusters.
2.  **Telemetry:** Hook a simple metrics dashboard to track exact AI API response lengths and execution speeds (`latency`) to optimize prompts.
3.  **Mobile Money:** Establish the Payment Gateway architecture directly in the `orders` module to natively accommodate MTN MoMo/Airtel Money APIs.
