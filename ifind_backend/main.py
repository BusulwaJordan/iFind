from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
from geopy.distance import geodesic
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from supabase import create_client
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Supabase client
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_ANON_KEY")
supabase = create_client(supabase_url, supabase_key)

# Load data from Supabase
print("Loading data from Supabase...")
businesses = pd.DataFrame(supabase.table('businesses').select('*').execute().data)
users = pd.DataFrame(supabase.table('users').select('*').execute().data)
interactions = pd.DataFrame(supabase.table('interactions').select('*').execute().data)
connections = pd.DataFrame(supabase.table('category_connections').select('*').execute().data)
print(f"Loaded {len(businesses)} businesses, {len(users)} users, {len(interactions)} interactions, {len(connections)} connections")

# Clean businesses data: NaN (from NULL DB values) isn't valid JSON and breaks
# both distance calculations and response serialization.
businesses['avg_rating'] = pd.to_numeric(businesses.get('avg_rating'), errors='coerce').fillna(0)
businesses['latitude'] = pd.to_numeric(businesses.get('latitude'), errors='coerce')
businesses['longitude'] = pd.to_numeric(businesses.get('longitude'), errors='coerce')
businesses = businesses.dropna(subset=['latitude', 'longitude']).reset_index(drop=True)
businesses['neighbourhood'] = businesses['neighbourhood'].fillna('')
businesses['category'] = businesses['category'].fillna('')
businesses['name'] = businesses['name'].fillna('Unknown')
print(f"After cleaning: {len(businesses)} businesses with valid coordinates")

# ---------- Final Hybrid Recommendation Function (unchanged) ----------
def final_hybrid_recommend(business_id, businesses_df, connections_df, interactions_df, top_n=10, max_distance=5.0):
    source = businesses_df[businesses_df['business_id'] == business_id].iloc[0]
    all_businesses = businesses_df[businesses_df['business_id'] != business_id].copy()
    
    # Rule-based scores
    compatible = connections_df[connections_df['category_a'] == source['category']]
    rule_scores = {}
    if len(compatible) > 0:
        source_coords = (source['latitude'], source['longitude'])
        for _, biz in all_businesses.iterrows():
            if biz['category'] in compatible['category_b'].values:
                biz_coords = (biz['latitude'], biz['longitude'])
                distance = geodesic(source_coords, biz_coords).km
                if distance <= max_distance:
                    rule_scores[biz['business_id']] = round(1 - (distance / max_distance), 3)
    
    # Content-based scores
    businesses_copy = businesses_df.copy()
    businesses_copy['description'] = businesses_copy['category'] + ' ' + businesses_copy['neighbourhood']
    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(businesses_copy['description'])
    similarity_matrix = cosine_similarity(tfidf_matrix)
    indices = pd.Series(businesses_copy.index, index=businesses_copy['business_id'])
    idx = indices[business_id]
    content_scores = {}
    for i, score in enumerate(similarity_matrix[idx]):
        bid = businesses_copy.iloc[i]['business_id']
        if bid != business_id:
            content_scores[bid] = round(score, 3)
    
    # Collaborative scores
    weight_map = {'view':1, 'search_click':2, 'profile_view':3, 'saved_business':4, 'review_posted':5, 'inquiry_sent':5}
    interactions_copy = interactions_df.copy()
    interactions_copy['weight'] = interactions_copy['interaction_type'].map(weight_map)
    user_biz_matrix = interactions_copy.pivot_table(index='user_id', columns='business_id', values='weight', aggfunc='sum', fill_value=0).T
    collab_scores = {}
    if business_id in user_biz_matrix.index:
        biz_similarity = cosine_similarity(user_biz_matrix)
        biz_sim_df = pd.DataFrame(biz_similarity, index=user_biz_matrix.index, columns=user_biz_matrix.index)
        for bid in biz_sim_df.index:
            if bid != business_id:
                collab_scores[bid] = round(biz_sim_df.loc[business_id, bid], 3)
    
    # Combine
    results = []
    source_coords = (source['latitude'], source['longitude'])
    for _, biz in all_businesses.iterrows():
        bid = biz['business_id']
        r_score = rule_scores.get(bid, 0)
        c_score = content_scores.get(bid, 0)
        cl_score = collab_scores.get(bid, 0)
        biz_coords = (biz['latitude'], biz['longitude'])
        distance = round(geodesic(source_coords, biz_coords).km, 3)
        scores = []
        if r_score > 0: scores.append(r_score)
        scores.append(c_score)
        if cl_score > 0: scores.append(cl_score)
        final_score = sum(scores) / len(scores) if scores else 0
        results.append({
            'business_id': bid, 'name': biz['name'], 'category': biz['category'],
            'neighbourhood': biz['neighbourhood'], 'distance_km': distance,
            'rule_score': r_score, 'content_score': c_score,
            'collaborative_score': cl_score, 'final_score': round(final_score, 3)
        })
    results_df = pd.DataFrame(results)
    return results_df.sort_values('final_score', ascending=False).head(top_n)

# ---------- API Endpoints ----------
@app.get("/recommend/business/{business_id}")
def recommend_business(business_id: str, top_n: int = 10):
    if business_id not in businesses['business_id'].values:
        raise HTTPException(404, "Business not found")
    recs = final_hybrid_recommend(business_id, businesses, connections, interactions, top_n)
    return recs.to_dict(orient='records')

@app.get("/search/nearby")
def nearby(lat: float, lon: float, radius_km: float = 5.0):
    results = []
    for _, biz in businesses.iterrows():
        dist = geodesic((lat, lon), (biz['latitude'], biz['longitude'])).km
        if dist <= radius_km:
            results.append({
                "business_id": biz['business_id'],
                "name": biz['name'],
                "category": biz['category'],
                "distance_km": round(dist, 3),
                "rating": biz['avg_rating']
            })
    return sorted(results, key=lambda x: x['distance_km'])

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)