/**
 * FoCoMap Comprehensive Sample Data Generator
 * Creates realistic test datasets for all FoCoMap features
 * 
 * Usage: node sample_data_generator.js
 * This will generate Firebase-ready JSON data for testing
 */

const fs = require('fs');

// Portuguese Golf Courses with Real GPS Coordinates
const GOLF_COURSES = [
  {
    name: "Quinta do Lago North",
    type: "Coastal",
    coordinates: { lat: 37.0234, lng: -8.0051 },
    holes: [
      { number: 1, lat: 37.0240, lng: -8.0060 },
      { number: 2, lat: 37.0245, lng: -8.0055 },
      { number: 3, lat: 37.0250, lng: -8.0050 },
      { number: 4, lat: 37.0255, lng: -8.0045 },
      { number: 5, lat: 37.0260, lng: -8.0040 },
      { number: 6, lat: 37.0265, lng: -8.0035 },
      { number: 7, lat: 37.0270, lng: -8.0030 },
      { number: 8, lat: 37.0275, lng: -8.0025 },
      { number: 9, lat: 37.0280, lng: -8.0020 },
      { number: 10, lat: 37.0285, lng: -8.0015 },
      { number: 11, lat: 37.0290, lng: -8.0010 },
      { number: 12, lat: 37.0295, lng: -8.0005 },
      { number: 13, lat: 37.0300, lng: -8.0000 },
      { number: 14, lat: 37.0305, lng: -7.9995 },
      { number: 15, lat: 37.0310, lng: -7.9990 },
      { number: 16, lat: 37.0315, lng: -7.9985 },
      { number: 17, lat: 37.0320, lng: -7.9980 },
      { number: 18, lat: 37.0325, lng: -7.9975 }
    ]
  },
  {
    name: "Troia Golf",
    type: "Links",
    coordinates: { lat: 38.4897, lng: -8.9089 },
    holes: [
      { number: 1, lat: 38.4900, lng: -8.9095 },
      { number: 2, lat: 38.4905, lng: -8.9090 },
      { number: 3, lat: 38.4910, lng: -8.9085 },
      { number: 4, lat: 38.4915, lng: -8.9080 },
      { number: 5, lat: 38.4920, lng: -8.9075 },
      { number: 6, lat: 38.4925, lng: -8.9070 },
      { number: 7, lat: 38.4930, lng: -8.9065 },
      { number: 8, lat: 38.4935, lng: -8.9060 },
      { number: 9, lat: 38.4940, lng: -8.9055 },
      { number: 10, lat: 38.4945, lng: -8.9050 },
      { number: 11, lat: 38.4950, lng: -8.9045 },
      { number: 12, lat: 38.4955, lng: -8.9040 },
      { number: 13, lat: 38.4960, lng: -8.9035 },
      { number: 14, lat: 38.4965, lng: -8.9030 },
      { number: 15, lat: 38.4970, lng: -8.9025 },
      { number: 16, lat: 38.4975, lng: -8.9020 },
      { number: 17, lat: 38.4980, lng: -8.9015 },
      { number: 18, lat: 38.4985, lng: -8.9010 }
    ]
  },
  {
    name: "Dom Pedro Victoria",
    type: "Parkland",
    coordinates: { lat: 37.1089, lng: -8.1234 },
    holes: [
      { number: 1, lat: 37.1095, lng: -8.1240 },
      { number: 2, lat: 37.1100, lng: -8.1235 },
      { number: 3, lat: 37.1105, lng: -8.1230 },
      { number: 4, lat: 37.1110, lng: -8.1225 },
      { number: 5, lat: 37.1115, lng: -8.1220 },
      { number: 6, lat: 37.1120, lng: -8.1215 },
      { number: 7, lat: 37.1125, lng: -8.1210 },
      { number: 8, lat: 37.1130, lng: -8.1205 },
      { number: 9, lat: 37.1135, lng: -8.1200 },
      { number: 10, lat: 37.1140, lng: -8.1195 },
      { number: 11, lat: 37.1145, lng: -8.1190 },
      { number: 12, lat: 37.1150, lng: -8.1185 },
      { number: 13, lat: 37.1155, lng: -8.1180 },
      { number: 14, lat: 37.1160, lng: -8.1175 },
      { number: 15, lat: 37.1165, lng: -8.1170 },
      { number: 16, lat: 37.1170, lng: -8.1165 },
      { number: 17, lat: 37.1175, lng: -8.1160 },
      { number: 18, lat: 37.1180, lng: -8.1155 }
    ]
  },
  {
    name: "Vale do Lobo Ocean",
    type: "Resort",
    coordinates: { lat: 37.0789, lng: -8.0456 },
    holes: [
      { number: 1, lat: 37.0795, lng: -8.0462 },
      { number: 2, lat: 37.0800, lng: -8.0457 },
      { number: 3, lat: 37.0805, lng: -8.0452 },
      { number: 4, lat: 37.0810, lng: -8.0447 },
      { number: 5, lat: 37.0815, lng: -8.0442 },
      { number: 6, lat: 37.0820, lng: -8.0437 },
      { number: 7, lat: 37.0825, lng: -8.0432 },
      { number: 8, lat: 37.0830, lng: -8.0427 },
      { number: 9, lat: 37.0835, lng: -8.0422 },
      { number: 10, lat: 37.0840, lng: -8.0417 },
      { number: 11, lat: 37.0845, lng: -8.0412 },
      { number: 12, lat: 37.0850, lng: -8.0407 },
      { number: 13, lat: 37.0855, lng: -8.0402 },
      { number: 14, lat: 37.0860, lng: -8.0397 },
      { number: 15, lat: 37.0865, lng: -8.0392 },
      { number: 16, lat: 37.0870, lng: -8.0387 },
      { number: 17, lat: 37.0875, lng: -8.0382 },
      { number: 18, lat: 37.0880, lng: -8.0377 }
    ]
  },
  {
    name: "Penha Longa Atlantic",
    type: "Mountain",
    coordinates: { lat: 38.7967, lng: -9.3789 },
    holes: [
      { number: 1, lat: 38.7973, lng: -9.3795 },
      { number: 2, lat: 38.7978, lng: -9.3790 },
      { number: 3, lat: 38.7983, lng: -9.3785 },
      { number: 4, lat: 38.7988, lng: -9.3780 },
      { number: 5, lat: 38.7993, lng: -9.3775 },
      { number: 6, lat: 38.7998, lng: -9.3770 },
      { number: 7, lat: 38.8003, lng: -9.3765 },
      { number: 8, lat: 38.8008, lng: -9.3760 },
      { number: 9, lat: 38.8013, lng: -9.3755 },
      { number: 10, lat: 38.8018, lng: -9.3750 },
      { number: 11, lat: 38.8023, lng: -9.3745 },
      { number: 12, lat: 38.8028, lng: -9.3740 },
      { number: 13, lat: 38.8033, lng: -9.3735 },
      { number: 14, lat: 38.8038, lng: -9.3730 },
      { number: 15, lat: 38.8043, lng: -9.3725 },
      { number: 16, lat: 38.8048, lng: -9.3720 },
      { number: 17, lat: 38.8053, lng: -9.3715 },
      { number: 18, lat: 38.8058, lng: -9.3710 }
    ]
  },
  {
    name: "Oitavos Dunes",
    type: "Links",
    coordinates: { lat: 38.7234, lng: -9.4678 },
    holes: [
      { number: 1, lat: 38.7240, lng: -9.4684 },
      { number: 2, lat: 38.7245, lng: -9.4679 },
      { number: 3, lat: 38.7250, lng: -9.4674 },
      { number: 4, lat: 38.7255, lng: -9.4669 },
      { number: 5, lat: 38.7260, lng: -9.4664 },
      { number: 6, lat: 38.7265, lng: -9.4659 },
      { number: 7, lat: 38.7270, lng: -9.4654 },
      { number: 8, lat: 38.7275, lng: -9.4649 },
      { number: 9, lat: 38.7280, lng: -9.4644 },
      { number: 10, lat: 38.7285, lng: -9.4639 },
      { number: 11, lat: 38.7290, lng: -9.4634 },
      { number: 12, lat: 38.7295, lng: -9.4629 },
      { number: 13, lat: 38.7300, lng: -9.4624 },
      { number: 14, lat: 38.7305, lng: -9.4619 },
      { number: 15, lat: 38.7310, lng: -9.4614 },
      { number: 16, lat: 38.7315, lng: -9.4609 },
      { number: 17, lat: 38.7320, lng: -9.4604 },
      { number: 18, lat: 38.7325, lng: -9.4599 }
    ]
  },
  {
    name: "Aroeira Challenge",
    type: "Parkland",
    coordinates: { lat: 38.5567, lng: -8.9234 },
    holes: [
      { number: 1, lat: 38.5573, lng: -8.9240 },
      { number: 2, lat: 38.5578, lng: -8.9235 },
      { number: 3, lat: 38.5583, lng: -8.9230 },
      { number: 4, lat: 38.5588, lng: -8.9225 },
      { number: 5, lat: 38.5593, lng: -8.9220 },
      { number: 6, lat: 38.5598, lng: -8.9215 },
      { number: 7, lat: 38.5603, lng: -8.9210 },
      { number: 8, lat: 38.5608, lng: -8.9205 },
      { number: 9, lat: 38.5613, lng: -8.9200 },
      { number: 10, lat: 38.5618, lng: -8.9195 },
      { number: 11, lat: 38.5623, lng: -8.9190 },
      { number: 12, lat: 38.5628, lng: -8.9185 },
      { number: 13, lat: 38.5633, lng: -8.9180 },
      { number: 14, lat: 38.5638, lng: -8.9175 },
      { number: 15, lat: 38.5643, lng: -8.9170 },
      { number: 16, lat: 38.5648, lng: -8.9165 },
      { number: 17, lat: 38.5653, lng: -8.9160 },
      { number: 18, lat: 38.5658, lng: -8.9155 }
    ]
  },
  {
    name: "Palmares Beach",
    type: "Coastal",
    coordinates: { lat: 37.1456, lng: -8.5789 },
    holes: [
      { number: 1, lat: 37.1462, lng: -8.5795 },
      { number: 2, lat: 37.1467, lng: -8.5790 },
      { number: 3, lat: 37.1472, lng: -8.5785 },
      { number: 4, lat: 37.1477, lng: -8.5780 },
      { number: 5, lat: 37.1482, lng: -8.5775 },
      { number: 6, lat: 37.1487, lng: -8.5770 },
      { number: 7, lat: 37.1492, lng: -8.5765 },
      { number: 8, lat: 37.1497, lng: -8.5760 },
      { number: 9, lat: 37.1502, lng: -8.5755 },
      { number: 10, lat: 37.1507, lng: -8.5750 },
      { number: 11, lat: 37.1512, lng: -8.5745 },
      { number: 12, lat: 37.1517, lng: -8.5740 },
      { number: 13, lat: 37.1522, lng: -8.5735 },
      { number: 14, lat: 37.1527, lng: -8.5730 },
      { number: 15, lat: 37.1532, lng: -8.5725 },
      { number: 16, lat: 37.1537, lng: -8.5720 },
      { number: 17, lat: 37.1542, lng: -8.5715 },
      { number: 18, lat: 37.1547, lng: -8.5710 }
    ]
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
      recoveryHoles.push(Math.floor(Math.random() * 18) + 1);
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
      date: date.toISOString(),
      courseName: course.name,
      courseType: course.type,
      coordinates: {
        latitude: course.coordinates.lat,
        longitude: course.coordinates.lng
      },
      mindsetFocus: focusAdjusted,
      mindsetConfidence: confidenceAdjusted,
      mindsetControl: controlAdjusted,
      bestCue: `${cue.emoji} ${cue.name}`,
      recoveryHoles: recoveryHoles,
      overallMindsetEmoji: mindsetEmoji,
      mindsetColor: mindsetColor,
      weather: weather.condition,
      technicalSummary: generateTechnicalSummary(),
      aiRoundSummary: generateAIRoundSummary(avgMindset, weather.condition, cue.name),
      voiceTranscription: generateVoiceTranscription(avgMindset, weather.condition),
      nlpProcessed: true,
      isLive: false,
      linkedGolfRoundId: "",
      holesPlayed: 18,
      createdTime: date.toISOString(),
      updatedTime: date.toISOString()
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
      
      // Shot outcome influenced by weather and mindset
      const weather = WEATHER_CONDITIONS.find(w => w.condition === round.weather);
      const avgMindset = (round.mindsetFocus + round.mindsetConfidence + round.mindsetControl) / 3;
      
      let outcomeCategory = "average";
      const performanceRoll = Math.random();
      
      if (avgMindset >= 4 && weather.mindsetImpact >= 0) {
        if (performanceRoll < 0.3) outcomeCategory = "excellent";
        else if (performanceRoll < 0.7) outcomeCategory = "good";
      } else if (avgMindset < 3 || weather.mindsetImpact < -1) {
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
      if (round.recoveryHoles.includes(holeNumber) && Math.random() < 0.3) {
        outcomeCategory = "recovery";
      }
      
      const outcomes = SHOT_OUTCOMES[outcomeCategory];
      const shotOutcome = outcomes[Math.floor(Math.random() * outcomes.length)];
      
      // Distance based on club
      const distance = club.distances[Math.floor(Math.random() * club.distances.length)];
      
      // Confidence level influenced by recent performance and mindset
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
      const shotCoordinates = {
        latitude: hole.lat + (Math.random() - 0.5) * 0.001,
        longitude: hole.lng + (Math.random() - 0.5) * 0.001
      };
      
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
        windCondition: round.weather,
        coordinates: shotCoordinates,
        aiShotInsight: generateAIShotInsight(outcomeCategory, club.name, round.weather),
        voiceTranscription: generateShotVoiceTranscription(club.name, shotOutcome, cue),
        nlpProcessed: true,
        shotTrend: shotTrend,
        missPattern: missPattern,
        performanceRating: performanceRating,
        clubIcon: getClubIcon(club.name),
        timestamp: new Date(round.date).toISOString(),
        createdTime: new Date(round.date).toISOString(),
        updatedTime: new Date(round.date).toISOString()
      });
    }
  });
  
  return shotLogs;
}

// Generate AI Insights based on patterns
function generateAIInsights(roundLogs, shotLogs) {
  const insights = [];
  
  // Pattern: 7 iron struggles in wind
  const sevenIronWindShots = shotLogs.filter(shot => 
    shot.clubUsed === "7 Iron" && 
    (shot.windCondition === "Windy" || shot.windCondition === "Strong Wind")
  );
  
  if (sevenIronWindShots.length >= 5) {
    const avgRating = sevenIronWindShots.reduce((sum, shot) => sum + shot.performanceRating, 0) / sevenIronWindShots.length;
    if (avgRating < 6) {
      insights.push({
        insightId: "insight_7iron_wind_001",
        userId: "test_user_123",
        insightType: "Pattern",
        title: "7 Iron Struggles in Wind",
        description: `Your 7 iron performance drops significantly in windy conditions. Average rating: ${avgRating.toFixed(1)}/10. Consider club up or focus on tempo cues.`,
        relatedClub: "7 Iron",
        relatedCue: "🫁 Breathing",
        confidence: 0.85,
        actionable: true,
        mapOverlayCoordinates: sevenIronWindShots.map(shot => shot.coordinates),
        createdTime: new Date().toISOString()
      });
    }
  }
  
  // Pattern: Confidence correlation with performance
  const highConfidenceShots = shotLogs.filter(shot => shot.confidenceLevel >= 8);
  const lowConfidenceShots = shotLogs.filter(shot => shot.confidenceLevel <= 4);
  
  if (highConfidenceShots.length >= 10 && lowConfidenceShots.length >= 10) {
    const highConfidenceAvg = highConfidenceShots.reduce((sum, shot) => sum + shot.performanceRating, 0) / highConfidenceShots.length;
    const lowConfidenceAvg = lowConfidenceShots.reduce((sum, shot) => sum + shot.performanceRating, 0) / lowConfidenceShots.length;
    
    if (highConfidenceAvg - lowConfidenceAvg > 2) {
      insights.push({
        insightId: "insight_confidence_correlation_001",
        userId: "test_user_123",
        insightType: "Mental",
        title: "Confidence Drives Performance",
        description: `Strong correlation between confidence and results. High confidence shots average ${highConfidenceAvg.toFixed(1)}/10 vs ${lowConfidenceAvg.toFixed(1)}/10 for low confidence.`,
        relatedClub: "All",
        relatedCue: "🧘 Self-Talk",
        confidence: 0.92,
        actionable: true,
        mapOverlayCoordinates: [],
        createdTime: new Date().toISOString()
      });
    }
  }
  
  // Pattern: Recovery hole success
  const recoveryRounds = roundLogs.filter(round => round.recoveryHoles.length > 0);
  if (recoveryRounds.length >= 5) {
    const avgRecoveryHoles = recoveryRounds.reduce((sum, round) => sum + round.recoveryHoles.length, 0) / recoveryRounds.length;
    
    insights.push({
      insightId: "insight_recovery_pattern_001",
      userId: "test_user_123",
      insightType: "Mental",
      title: "Strong Recovery Mindset",
      description: `You average ${avgRecoveryHoles.toFixed(1)} recovery holes per round, showing excellent mental resilience. Your best cue appears to be visualization.`,
      relatedClub: "Mental Game",
      relatedCue: "👁️ Visualization",
      confidence: 0.78,
      actionable: false,
      mapOverlayCoordinates: recoveryRounds.map(round => round.coordinates),
      createdTime: new Date().toISOString()
    });
  }
  
  return insights;
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
    return `Excellent mental performance today. Your ${cue} cue worked well despite ${weather.toLowerCase()} conditions. Focus on maintaining this mindset consistency.`;
  } else if (avgMindset >= 3) {
    return `Solid mental game with room for improvement. The ${weather.toLowerCase()} conditions affected your confidence slightly. Consider strengthening your ${cue} routine.`;
  } else {
    return `Challenging round mentally. ${weather} conditions impacted your focus. Work on your ${cue} technique and consider adding breathing exercises for tough conditions.`;
  }
}

function generateVoiceTranscription(avgMindset, weather) {
  const transcriptions = [
    `Felt really good out there today, ${weather.toLowerCase()} but managed to stay focused`,
    `Tough conditions with the ${weather.toLowerCase()}, but my mental game held up`,
    `Started shaky but found my rhythm, breathing really helped`,
    `Great round mentally, visualization was working perfectly`,
    `Struggled with confidence early, but recovered well on back nine`,
    `Wind was challenging but stayed committed to my routine`,
    `Really pleased with how I handled the pressure today`,
    `Mental game needs work, got frustrated too easily`
  ];
  return transcriptions[Math.floor(Math.random() * transcriptions.length)];
}

function generateShotShape() {
  const shapes = ["straight", "draw", "fade", "slight draw", "slight fade", "hook", "slice"];
  return shapes[Math.floor(Math.random() * shapes.length)];
}

function generateAIShotInsight(outcomeCategory, club, weather) {
  const insights = {
    excellent: [
      `Perfect tempo with your ${club} today. Maintain this rhythm.`,
      `Great club selection for these conditions. Trust your instincts.`,
      `Excellent commitment to the shot. This is your baseline performance.`
    ],
    good: [
      `Solid ${club} technique. Minor adjustments could make this excellent.`,
      `Good decision-making in ${weather.toLowerCase()} conditions.`,
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

// Main generation function
function generateAllSampleData() {
  console.log("🏌️ Generating FoCoMap Sample Data...\n");
  
  const roundLogs = generateRoundLogs();
  console.log(`✅ Generated ${roundLogs.length} round logs`);
  
  const shotLogs = generateShotLogs(roundLogs);
  console.log(`✅ Generated ${shotLogs.length} shot logs`);
  
  const aiInsights = generateAIInsights(roundLogs, shotLogs);
  console.log(`✅ Generated ${aiInsights.length} AI insights`);
  
  const sampleData = {
    round_logs: roundLogs,
    shot_logs: shotLogs,
    ai_insights: aiInsights,
    metadata: {
      generated_at: new Date().toISOString(),
      total_rounds: roundLogs.length,
      total_shots: shotLogs.length,
      total_insights: aiInsights.length,
      courses_covered: GOLF_COURSES.length,
      date_range: {
        from: roundLogs[0]?.date,
        to: roundLogs[roundLogs.length - 1]?.date
      }
    }
  };
  
  // Write to file
  fs.writeFileSync('focomap_sample_data.json', JSON.stringify(sampleData, null, 2));
  console.log("\n📁 Sample data written to focomap_sample_data.json");
  
  // Generate Firebase import script
  generateFirebaseImportScript(sampleData);
  
  return sampleData;
}

function generateFirebaseImportScript(data) {
  const importScript = `
/**
 * Firebase Import Script for FoCoMap Sample Data
 * Run this in Firebase Functions or Admin SDK environment
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (configure with your credentials)
// admin.initializeApp();

const db = admin.firestore();

async function importSampleData() {
  const batch = db.batch();
  
  console.log('🔥 Starting Firebase import...');
  
  // Import Round Logs
  ${JSON.stringify(data.round_logs, null, 2)}.forEach(round => {
    const roundRef = db.collection('round_logs').doc();
    batch.set(roundRef, {
      ...round,
      date: admin.firestore.Timestamp.fromDate(new Date(round.date)),
      createdTime: admin.firestore.Timestamp.fromDate(new Date(round.createdTime)),
      updatedTime: admin.firestore.Timestamp.fromDate(new Date(round.updatedTime))
    });
  });
  
  // Import Shot Logs
  ${JSON.stringify(data.shot_logs, null, 2)}.forEach(shot => {
    const shotRef = db.collection('shot_logs').doc();
    batch.set(shotRef, {
      ...shot,
      timestamp: admin.firestore.Timestamp.fromDate(new Date(shot.timestamp)),
      createdTime: admin.firestore.Timestamp.fromDate(new Date(shot.createdTime)),
      updatedTime: admin.firestore.Timestamp.fromDate(new Date(shot.updatedTime))
    });
  });
  
  // Import AI Insights
  ${JSON.stringify(data.ai_insights, null, 2)}.forEach(insight => {
    const insightRef = db.collection('ai_insights').doc();
    batch.set(insightRef, {
      ...insight,
      createdTime: admin.firestore.Timestamp.fromDate(new Date(insight.createdTime))
    });
  });
  
  try {
    await batch.commit();
    console.log('✅ Sample data imported successfully!');
    console.log(\`📊 Imported: \${${data.round_logs.length}} rounds, \${${data.shot_logs.length}} shots, \${${data.ai_insights.length}} insights\`);
  } catch (error) {
    console.error('❌ Import failed:', error);
  }
}

// Run import
importSampleData();
`;

  fs.writeFileSync('firebase_import_script.js', importScript);
  console.log("📁 Firebase import script written to firebase_import_script.js");
}

// Execute if run directly
if (require.main === module) {
  generateAllSampleData();
}

module.exports = {
  generateAllSampleData,
  GOLF_COURSES,
  MENTAL_CUES,
  WEATHER_CONDITIONS,
  CLUBS
};

