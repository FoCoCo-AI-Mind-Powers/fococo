/**
 * Firebase Cloud Function to Import FoCoMap Sample Data
 * 
 * This function imports comprehensive test data for FoCoMap including:
 * - 25 rounds across 8 Portuguese golf courses
 * - 500+ shots with realistic patterns
 * - AI insights based on performance data
 * 
 * Usage:
 * 1. Deploy: firebase deploy --only functions:importSampleData
 * 2. Call: https://your-project.cloudfunctions.net/importSampleData
 * 3. Or trigger via Firebase Console
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Portuguese Golf Courses with Real GPS Coordinates
const GOLF_COURSES = [
  {
    name: "Quinta do Lago North",
    type: "Coastal",
    coordinates: { lat: 37.0234, lng: -8.0051 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 37.0240 + (i * 0.0005),
      lng: -8.0060 + (i * 0.0005)
    }))
  },
  {
    name: "Troia Golf",
    type: "Links",
    coordinates: { lat: 38.4897, lng: -8.9089 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 38.4900 + (i * 0.0005),
      lng: -8.9095 + (i * 0.0005)
    }))
  },
  {
    name: "Dom Pedro Victoria",
    type: "Parkland",
    coordinates: { lat: 37.1089, lng: -8.1234 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 37.1095 + (i * 0.0005),
      lng: -8.1240 + (i * 0.0005)
    }))
  },
  {
    name: "Vale do Lobo Ocean",
    type: "Resort",
    coordinates: { lat: 37.0789, lng: -8.0456 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 37.0795 + (i * 0.0005),
      lng: -8.0462 + (i * 0.0005)
    }))
  },
  {
    name: "Penha Longa Atlantic",
    type: "Mountain",
    coordinates: { lat: 38.7967, lng: -9.3789 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 38.7973 + (i * 0.0005),
      lng: -9.3795 + (i * 0.0005)
    }))
  },
  {
    name: "Oitavos Dunes",
    type: "Links",
    coordinates: { lat: 38.7234, lng: -9.4678 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 38.7240 + (i * 0.0005),
      lng: -9.4684 + (i * 0.0005)
    }))
  },
  {
    name: "Aroeira Challenge",
    type: "Parkland",
    coordinates: { lat: 38.5567, lng: -8.9234 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 38.5573 + (i * 0.0005),
      lng: -9.9240 + (i * 0.0005)
    }))
  },
  {
    name: "Palmares Beach",
    type: "Coastal",
    coordinates: { lat: 37.1456, lng: -8.5789 },
    holes: Array.from({ length: 18 }, (_, i) => ({
      number: i + 1,
      lat: 37.1462 + (i * 0.0005),
      lng: -8.5795 + (i * 0.0005)
    }))
  }
];

// Mental Cues with Icons and Effectiveness
const MENTAL_CUES = [
  { name: "Visualization", emoji: "👁️", effectiveness: [3, 4, 5] },
  { name: "Breathing", emoji: "🫁", effectiveness: [4, 5] },
  { name: "Self-Talk", emoji: "🧘", effectiveness: [3, 4, 5] },
  { name: "Letting Go", emoji: "✋", effectiveness: [2, 3, 4] },
  { name: "Focus Point", emoji: "🎯", effectiveness: [4, 5] },
  { name: "Routine", emoji: "🔄", effectiveness: [3, 4, 5] }
];

// Weather Conditions with Impact on Performance
const WEATHER_CONDITIONS = [
  { condition: "Calm", mindsetImpact: 1, confidenceBoost: true },
  { condition: "Light Breeze", mindsetImpact: 0, confidenceBoost: false },
  { condition: "Windy", mindsetImpact: -1, confidenceBoost: false },
  { condition: "Strong Wind", mindsetImpact: -2, confidenceBoost: false },
  { condition: "Light Rain", mindsetImpact: -1, confidenceBoost: false },
  { condition: "Heavy Rain", mindsetImpact: -2, confidenceBoost: false }
];

// Club Types with Distance and Accuracy Patterns
const CLUBS = [
  { name: "Driver", distances: [240, 260, 280, 300], accuracy: 0.7 },
  { name: "3 Wood", distances: [210, 230, 250], accuracy: 0.8 },
  { name: "5 Iron", distances: [160, 175, 190], accuracy: 0.85 },
  { name: "6 Iron", distances: [150, 165, 180], accuracy: 0.85 },
  { name: "7 Iron", distances: [140, 155, 170], accuracy: 0.9 },
  { name: "8 Iron", distances: [130, 145, 160], accuracy: 0.9 },
  { name: "9 Iron", distances: [120, 135, 150], accuracy: 0.92 },
  { name: "PW", distances: [100, 115, 130], accuracy: 0.95 },
  { name: "SW", distances: [60, 80, 100], accuracy: 0.9 },
  { name: "LW", distances: [40, 60, 80], accuracy: 0.85 },
  { name: "Putter", distances: [3, 8, 15, 25], accuracy: 0.8 }
];

// Shot Outcomes with Patterns
const SHOT_OUTCOMES = {
  excellent: ["Pin high", "Fairway center", "Green center", "Birdie putt"],
  good: ["Fairway left", "Fairway right", "Green left", "Green right", "Par putt"],
  average: ["Light rough", "Fringe", "Back of green", "Front of green"],
  poor: ["Heavy rough", "Bunker", "Water hazard", "OB left", "OB right"],
  recovery: ["Punch out", "Chip close", "Sand save", "Up and down"]
};

// Generate realistic dates over past 6 months
function generateRoundDates(count) {
  const dates = [];
  const now = new Date();
  const sixMonthsAgo = new Date(now.getTime() - (6 * 30 * 24 * 60 * 60 * 1000));
  
  for (let i = 0; i < count; i++) {
    const randomTime = sixMonthsAgo.getTime() + 
      Math.random() * (now.getTime() - sixMonthsAgo.getTime());
    dates.push(new Date(randomTime));
  }
  
  return dates.sort((a, b) => a - b);
}

// Generate Round Logs with Realistic Patterns
function generateRoundLogs() {
  const roundLogs = [];
  const dates = generateRoundDates(25); // 25 rounds over 6 months
  
  dates.forEach((date, index) => {
    const course = GOLF_COURSES[Math.floor(Math.random() * GOLF_COURSES.length)];
    const weather = WEATHER_CONDITIONS[Math.floor(Math.random() * WEATHER_CONDITIONS.length)];
    const cue = MENTAL_CUES[Math.floor(Math.random() * MENTAL_CUES.length)];
    
    // Create realistic mindset patterns
    const baseFocus = 3 + Math.floor(Math.random() * 3); // 3-5
    const baseConfidence = 3 + Math.floor(Math.random() * 3); // 3-5
    const baseControl = 3 + Math.floor(Math.random() * 3); // 3-5
    
    // Weather impact
    const focusAdjusted = Math.max(1, Math.min(5, baseFocus + weather.mindsetImpact));
    const confidenceAdjusted = Math.max(1, Math.min(5, baseConfidence + weather.mindsetImpact));
    const controlAdjusted = Math.max(1, Math.min(5, baseControl + weather.mindsetImpact));
    
    // Recovery holes (1-3 holes where mental game helped)
    const recoveryCount = Math.floor(Math.random() * 4); // 0-3 recovery holes
    const recoveryHoles = [];
    for (let i = 0; i < recoveryCount; i++) {
      recoveryHoles.push((Math.floor(Math.random() * 18) + 1).toString());
    }
    
    // Overall mindset emoji based on average scores
    const avgMindset = (focusAdjusted + confidenceAdjusted + controlAdjusted) / 3;
    let mindsetEmoji = "😐";
    if (avgMindset >= 4.5) mindsetEmoji = "😊";
    else if (avgMindset >= 4) mindsetEmoji = "🙂";
    else if (avgMindset >= 3) mindsetEmoji = "😐";
    else if (avgMindset >= 2) mindsetEmoji = "😕";
    else mindsetEmoji = "😞";
    
    // Mindset color for map visualization
    let mindsetColor = "yellow";
    if (avgMindset >= 4) mindsetColor = "green";
    else if (avgMindset < 3) mindsetColor = "red";
    
    const roundId = `round_${String(index + 1).padStart(3, '0')}_${date.getTime()}`;
    
    roundLogs.push({
      userId: "test_user_123",
      roundId: roundId,
      date: admin.firestore.Timestamp.fromDate(date),
      courseName: course.name,
      courseType: course.type,
      coordinates: new admin.firestore.GeoPoint(course.coordinates.lat, course.coordinates.lng),
      mindsetFocus: focusAdjusted,
      mindsetConfidence: confidenceAdjusted,
      mindsetControl: controlAdjusted,
      bestCue: `${cue.emoji} ${cue.name}`,
      recoveryHoles: recoveryHoles,
      overallMindsetEmoji: mindsetEmoji,
      mindsetColor: mindsetColor,
      technicalSummary: generateTechnicalSummary(),
      aiRoundSummary: generateAIRoundSummary(avgMindset, weather.condition, cue.name),
      voiceTranscription: generateVoiceTranscription(avgMindset, weather.condition),
      nlpProcessed: true,
      isLive: false,
      linkedGolfRoundId: "",
      createdTime: admin.firestore.Timestamp.fromDate(date),
      updatedTime: admin.firestore.Timestamp.fromDate(date)
    });
  });
  
  return roundLogs;
}

// Generate Shot Logs with Realistic Patterns
function generateShotLogs(roundLogs) {
  const shotLogs = [];
  let shotCounter = 1;
  
  roundLogs.forEach(round => {
    const course = GOLF_COURSES.find(c => c.name === round.courseName);
    const shotsPerRound = 15 + Math.floor(Math.random() * 10); // 15-25 shots per round
    
    for (let i = 0; i < shotsPerRound; i++) {
      const holeNumber = Math.floor(Math.random() * 18) + 1;
      const hole = course.holes.find(h => h.number === holeNumber);
      const club = CLUBS[Math.floor(Math.random() * CLUBS.length)];
      
      // Shot outcome influenced by mindset
      const avgMindset = (round.mindsetFocus + round.mindsetConfidence + round.mindsetControl) / 3;
      
      let outcomeCategory = "average";
      const performanceRoll = Math.random();
      
      if (avgMindset >= 4) {
        if (performanceRoll < 0.3) outcomeCategory = "excellent";
        else if (performanceRoll < 0.7) outcomeCategory = "good";
      } else if (avgMindset < 3) {
        if (performanceRoll < 0.2) outcomeCategory = "poor";
        else if (performanceRoll < 0.4) outcomeCategory = "average";
        else outcomeCategory = "good";
      } else {
        if (performanceRoll < 0.1) outcomeCategory = "excellent";
        else if (performanceRoll < 0.5) outcomeCategory = "good";
        else if (performanceRoll < 0.8) outcomeCategory = "average";
        else outcomeCategory = "poor";
      }
      
      // Recovery shots on recovery holes
      if (round.recoveryHoles.includes(holeNumber.toString()) && Math.random() < 0.3) {
        outcomeCategory = "recovery";
      }
      
      const outcomes = SHOT_OUTCOMES[outcomeCategory];
      const shotOutcome = outcomes[Math.floor(Math.random() * outcomes.length)];
      
      // Distance based on club
      const distance = club.distances[Math.floor(Math.random() * club.distances.length)];
      
      // Confidence level influenced by mindset
      const confidenceLevel = Math.max(1, Math.min(10, 
        Math.round(round.mindsetConfidence * 2 + Math.random() * 2 - 1)
      ));
      
      // Cue used (sometimes matches round's best cue)
      const cue = Math.random() < 0.4 ? 
        round.bestCue : 
        `${MENTAL_CUES[Math.floor(Math.random() * MENTAL_CUES.length)].emoji} ${MENTAL_CUES[Math.floor(Math.random() * MENTAL_CUES.length)].name}`;
      
      // Shot trend based on performance
      let shotTrend = "stable";
      if (outcomeCategory === "excellent" || outcomeCategory === "recovery") shotTrend = "improving";
      else if (outcomeCategory === "poor") shotTrend = "declining";
      
      // Miss pattern for poor shots
      let missPattern = "none";
      if (outcomeCategory === "poor") {
        const patterns = ["short", "long", "left", "right", "short left", "short right", "long left", "long right"];
        missPattern = patterns[Math.floor(Math.random() * patterns.length)];
      }
      
      // Performance rating
      const performanceRating = outcomeCategory === "excellent" ? 9 + Math.floor(Math.random() * 2) :
                              outcomeCategory === "good" ? 7 + Math.floor(Math.random() * 2) :
                              outcomeCategory === "average" ? 5 + Math.floor(Math.random() * 3) :
                              outcomeCategory === "recovery" ? 8 + Math.floor(Math.random() * 2) :
                              2 + Math.floor(Math.random() * 3);
      
      // Add slight GPS variation for shot location
      const shotCoordinates = new admin.firestore.GeoPoint(
        hole.lat + (Math.random() - 0.5) * 0.001,
        hole.lng + (Math.random() - 0.5) * 0.001
      );
      
      const shotId = `shot_${String(shotCounter).padStart(4, '0')}_${round.roundId}`;
      shotCounter++;
      
      shotLogs.push({
        userId: "test_user_123",
        roundId: round.roundId,
        shotId: shotId,
        holeNumber: holeNumber,
        clubUsed: club.name,
        distanceAttempted: distance,
        shotShape: generateShotShape(),
        shotOutcome: shotOutcome,
        cueUsed: cue,
        confidenceLevel: confidenceLevel,
        windCondition: "Calm", // Simplified for schema compatibility
        coordinates: shotCoordinates,
        aiShotInsight: generateAIShotInsight(outcomeCategory, club.name),
        voiceTranscription: generateShotVoiceTranscription(club.name, shotOutcome, cue),
        nlpProcessed: true,
        shotTrend: shotTrend,
        missPattern: missPattern,
        performanceRating: performanceRating,
        clubIcon: getClubIcon(club.name),
        timestamp: admin.firestore.Timestamp.fromDate(round.date.toDate()),
        createdTime: admin.firestore.Timestamp.fromDate(round.date.toDate()),
        updatedTime: admin.firestore.Timestamp.fromDate(round.date.toDate())
      });
    }
  });
  
  return shotLogs;
}

// Helper functions for realistic data generation
function generateTechnicalSummary() {
  const summaries = [
    "Solid driving today, struggled with approach shots",
    "Great iron play, putting let me down",
    "Excellent short game, driver was inconsistent",
    "Strong all-around performance with minor lapses",
    "Fought through tough conditions, stayed patient",
    "Ball striking was crisp, course management improved",
    "Struggled early but found rhythm on back nine",
    "Consistent performance throughout the round"
  ];
  return summaries[Math.floor(Math.random() * summaries.length)];
}

function generateAIRoundSummary(avgMindset, weather, cue) {
  if (avgMindset >= 4) {
    return `Excellent mental performance today. Your ${cue} cue worked well despite conditions. Focus on maintaining this mindset consistency.`;
  } else if (avgMindset >= 3) {
    return `Solid mental game with room for improvement. Consider strengthening your ${cue} routine.`;
  } else {
    return `Challenging round mentally. Work on your ${cue} technique and consider adding breathing exercises for tough conditions.`;
  }
}

function generateVoiceTranscription(avgMindset, weather) {
  const transcriptions = [
    "Felt really good out there today, managed to stay focused",
    "Tough conditions but my mental game held up",
    "Started shaky but found my rhythm, breathing really helped",
    "Great round mentally, visualization was working perfectly",
    "Struggled with confidence early, but recovered well on back nine",
    "Really pleased with how I handled the pressure today",
    "Mental game needs work, got frustrated too easily"
  ];
  return transcriptions[Math.floor(Math.random() * transcriptions.length)];
}

function generateShotShape() {
  const shapes = ["straight", "draw", "fade", "slight draw", "slight fade"];
  return shapes[Math.floor(Math.random() * shapes.length)];
}

function generateAIShotInsight(outcomeCategory, club) {
  const insights = {
    excellent: [
      `Perfect tempo with your ${club} today. Maintain this rhythm.`,
      `Great club selection for these conditions. Trust your instincts.`,
      `Excellent commitment to the shot. This is your baseline performance.`
    ],
    good: [
      `Solid ${club} technique. Minor adjustments could make this excellent.`,
      `Good decision-making in these conditions.`,
      `Nice recovery and course management with this shot.`
    ],
    average: [
      `Your ${club} needs attention. Consider tempo work on the range.`,
      `Decent shot but room for improvement with setup fundamentals.`,
      `Average result - focus on your pre-shot routine consistency.`
    ],
    poor: [
      `${club} technique breakdown. Work on basics and slow down tempo.`,
      `Poor decision for these conditions. Consider club selection strategy.`,
      `Mental error led to technical breakdown. Reset and refocus.`
    ],
    recovery: [
      `Excellent recovery mindset! This shows your mental strength.`,
      `Great problem-solving with this ${club} shot.`,
      `Perfect example of staying positive after adversity.`
    ]
  };
  
  const categoryInsights = insights[outcomeCategory];
  return categoryInsights[Math.floor(Math.random() * categoryInsights.length)];
}

function generateShotVoiceTranscription(club, outcome, cue) {
  return `${club} shot, ${outcome.toLowerCase()}, used my ${cue.split(' ')[1]} cue`;
}

function getClubIcon(clubName) {
  const icons = {
    "Driver": "🏌️",
    "3 Wood": "🏌️",
    "5 Iron": "⛳",
    "6 Iron": "⛳",
    "7 Iron": "⛳",
    "8 Iron": "⛳",
    "9 Iron": "⛳",
    "PW": "🎯",
    "SW": "🎯",
    "LW": "🎯",
    "Putter": "⛳"
  };
  return icons[clubName] || "⛳";
}

// Main Cloud Function
exports.importSampleData = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🏌️ Starting FoCoMap sample data import...');
    
    // Generate data
    const roundLogs = generateRoundLogs();
    const shotLogs = generateShotLogs(roundLogs);
    
    console.log(`Generated ${roundLogs.length} rounds and ${shotLogs.length} shots`);
    
    // Import in batches to avoid Firestore limits
    const batchSize = 500;
    let totalImported = 0;
    
    // Import Round Logs
    for (let i = 0; i < roundLogs.length; i += batchSize) {
      const batch = db.batch();
      const batchData = roundLogs.slice(i, i + batchSize);
      
      batchData.forEach(round => {
        const roundRef = db.collection('round_logs').doc();
        batch.set(roundRef, round);
      });
      
      await batch.commit();
      totalImported += batchData.length;
      console.log(`Imported ${totalImported}/${roundLogs.length} rounds`);
    }
    
    // Import Shot Logs
    totalImported = 0;
    for (let i = 0; i < shotLogs.length; i += batchSize) {
      const batch = db.batch();
      const batchData = shotLogs.slice(i, i + batchSize);
      
      batchData.forEach(shot => {
        const shotRef = db.collection('shot_logs').doc();
        batch.set(shotRef, shot);
      });
      
      await batch.commit();
      totalImported += batchData.length;
      console.log(`Imported ${totalImported}/${shotLogs.length} shots`);
    }
    
    // Create summary document for testing
    await db.collection('focomap_test_data').doc('summary').set({
      importedAt: admin.firestore.Timestamp.now(),
      totalRounds: roundLogs.length,
      totalShots: shotLogs.length,
      coursesUsed: GOLF_COURSES.map(c => c.name),
      dateRange: {
        from: roundLogs[0].date,
        to: roundLogs[roundLogs.length - 1].date
      },
      testUserId: "test_user_123",
      status: "completed"
    });
    
    console.log('✅ Sample data import completed successfully!');
    
    res.status(200).json({
      success: true,
      message: 'FoCoMap sample data imported successfully',
      data: {
        rounds: roundLogs.length,
        shots: shotLogs.length,
        courses: GOLF_COURSES.length,
        testUserId: "test_user_123"
      }
    });
    
  } catch (error) {
    console.error('❌ Import failed:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      message: 'Failed to import sample data'
    });
  }
});

// Helper function to clear test data (for development)
exports.clearSampleData = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🗑️ Clearing sample data...');
    
    // Delete all test data
    const roundsQuery = db.collection('round_logs').where('userId', '==', 'test_user_123');
    const shotsQuery = db.collection('shot_logs').where('userId', '==', 'test_user_123');
    
    const [roundsSnapshot, shotsSnapshot] = await Promise.all([
      roundsQuery.get(),
      shotsQuery.get()
    ]);
    
    // Delete in batches
    const deletePromises = [];
    
    // Delete rounds
    for (let i = 0; i < roundsSnapshot.docs.length; i += 500) {
      const batch = db.batch();
      const batchDocs = roundsSnapshot.docs.slice(i, i + 500);
      batchDocs.forEach(doc => batch.delete(doc.ref));
      deletePromises.push(batch.commit());
    }
    
    // Delete shots
    for (let i = 0; i < shotsSnapshot.docs.length; i += 500) {
      const batch = db.batch();
      const batchDocs = shotsSnapshot.docs.slice(i, i + 500);
      batchDocs.forEach(doc => batch.delete(doc.ref));
      deletePromises.push(batch.commit());
    }
    
    await Promise.all(deletePromises);
    
    // Delete summary
    await db.collection('focomap_test_data').doc('summary').delete();
    
    console.log('✅ Sample data cleared successfully!');
    
    res.status(200).json({
      success: true,
      message: 'Sample data cleared successfully',
      deleted: {
        rounds: roundsSnapshot.size,
        shots: shotsSnapshot.size
      }
    });
    
  } catch (error) {
    console.error('❌ Clear failed:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

