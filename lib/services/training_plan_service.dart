import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fo_co_co/auth/firebase_auth/auth_util.dart';
import 'package:fo_co_co/backend/backend.dart';
import 'package:fo_co_co/backend/schema/training_plans_record.dart';
import 'package:fo_co_co/backend/schema/coaching_modules_record.dart';

/// TrainingPlanService
/// Manages training plans for users - creation, updates, and progress tracking
class TrainingPlanService {
  static final TrainingPlanService _instance = TrainingPlanService._internal();
  factory TrainingPlanService() => _instance;
  TrainingPlanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current active training plan for user
  Future<TrainingPlansRecord?> getCurrentPlan(String userId) async {
    try {
      final snapshot = await TrainingPlansRecord.collection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return TrainingPlansRecord.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      print('❌ Error getting current plan: $e');
      return null;
    }
  }

  /// Get current active training plan stream
  Stream<TrainingPlansRecord?> getCurrentPlanStream(String userId) {
    return TrainingPlansRecord.collection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return TrainingPlansRecord.fromSnapshot(snapshot.docs.first);
    });
  }

  /// Generate a new training plan based on user's VARK preferences and progress
  Future<TrainingPlansRecord> generateNewPlan({
    required String userId,
    String? focusPillar,
  }) async {
    try {
      // Get user's VARK preferences
      final userDoc = await UserRecord.collection.doc(userId).get();
      final userData = userDoc.exists
          ? UserRecord.fromSnapshot(userDoc)
          : null;

      // Determine focus pillar (default to confidence if not specified)
      final targetPillar = focusPillar ?? 'confidence';

      // Query modules for the target pillar
      final modulesSnapshot = await CoachingModulesRecord.collection
          .where('isActive', isEqualTo: true)
          .where('pillar', isEqualTo: targetPillar)
          .orderBy('averageRating', descending: true)
          .limit(8)
          .get();

      final modules = modulesSnapshot.docs
          .map((doc) => CoachingModulesRecord.fromSnapshot(doc))
          .toList();

      if (modules.isEmpty) {
        throw Exception('No modules found for pillar: $targetPillar');
      }

      // Create plan
      final planId = _firestore.collection('training_plans').doc().id;
      final totalDuration = modules.fold<int>(
          0, (sum, module) => sum + (module.duration));

      final planData = {
        'planId': planId,
        'userId': userId,
        'title': '${targetPillar.toUpperCase()} Training Plan',
        'description':
            'Structured lessons tailored to your ${targetPillar} development',
        'modules': modules.map((m) => m.moduleId).toList(),
        'currentModuleIndex': 0,
        'isActive': true,
        'createdTime': FieldValue.serverTimestamp(),
        'updatedTime': FieldValue.serverTimestamp(),
        'completedModules': [],
        'totalModules': modules.length,
        'estimatedDuration': totalDuration,
      };

      // Deactivate any existing active plans
      await _deactivateExistingPlans(userId);

      // Create new plan
      final docRef = TrainingPlansRecord.collection.doc();
      await docRef.set(planData);

      // Update user's lastTrainingPlanId
      await UserRecord.collection.doc(userId).update({
        'lastTrainingPlanId': docRef.id,
      });

      return TrainingPlansRecord.fromSnapshot(
          await docRef.get() as DocumentSnapshot);
    } catch (e) {
      print('❌ Error generating new plan: $e');
      rethrow;
    }
  }

  /// Continue with the current plan - get next module
  Future<CoachingModulesRecord?> getNextModuleInPlan(
      TrainingPlansRecord plan) async {
    try {
      if (plan.currentModuleIndex >= plan.modules.length) {
        return null; // Plan completed
      }

      final nextModuleId = plan.modules[plan.currentModuleIndex];
      final moduleSnapshot = await CoachingModulesRecord.collection
          .where('moduleId', isEqualTo: nextModuleId)
          .limit(1)
          .get();

      if (moduleSnapshot.docs.isEmpty) {
        return null;
      }

      return CoachingModulesRecord.fromSnapshot(moduleSnapshot.docs.first);
    } catch (e) {
      print('❌ Error getting next module: $e');
      return null;
    }
  }

  /// Update plan progress when a module is completed
  Future<void> updatePlanProgress({
    required String planId,
    required String moduleId,
  }) async {
    try {
      final planDoc = await TrainingPlansRecord.collection.doc(planId).get();
      if (!planDoc.exists) {
        throw Exception('Plan not found');
      }

      final plan = TrainingPlansRecord.fromSnapshot(planDoc);
      final completedModules = List<String>.from(plan.completedModules);
      
      if (!completedModules.contains(moduleId)) {
        completedModules.add(moduleId);
      }

      final newIndex = plan.currentModuleIndex + 1;
      final isCompleted = newIndex >= plan.modules.length;

      await TrainingPlansRecord.collection.doc(planId).update({
        'completedModules': completedModules,
        'currentModuleIndex': newIndex,
        'isActive': !isCompleted, // Deactivate if completed
        'updatedTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating plan progress: $e');
      rethrow;
    }
  }

  /// Deactivate all existing active plans for a user
  Future<void> _deactivateExistingPlans(String userId) async {
    try {
      final snapshot = await TrainingPlansRecord.collection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedTime': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error deactivating existing plans: $e');
    }
  }

  /// Refresh/regenerate plan
  Future<TrainingPlansRecord> refreshPlan(String userId) async {
    final currentPlan = await getCurrentPlan(userId);
    if (currentPlan != null) {
      // Deactivate current plan
      await TrainingPlansRecord.collection.doc(currentPlan.reference.id).update({
        'isActive': false,
        'updatedTime': FieldValue.serverTimestamp(),
      });
    }

    // Generate new plan
    return await generateNewPlan(userId: userId);
  }
}

