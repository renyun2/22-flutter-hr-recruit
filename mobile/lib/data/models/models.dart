class HrUser {
  HrUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.email,
  });

  final String id;
  final String username;
  final String name;
  final String role;
  final String? email;

  factory HrUser.fromJson(Map<String, dynamic> json) => HrUser(
        id: json['id'] as String,
        username: json['username'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        email: json['email'] as String?,
      );

  bool get isHr => role == 'hr';
  bool get isManager => role == 'hiring_manager';
  bool get isCandidate => role == 'candidate';
  bool get isInterviewer => role == 'interviewer';
}

class Job {
  Job({
    required this.id,
    required this.title,
    required this.department,
    required this.location,
    required this.description,
    required this.requirements,
    required this.salaryMin,
    required this.salaryMax,
    required this.status,
    this.applicationCount,
    this.createdAt,
  });

  final String id;
  final String title;
  final String department;
  final String location;
  final String description;
  final String requirements;
  final num salaryMin;
  final num salaryMax;
  final String status;
  final int? applicationCount;
  final String? createdAt;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String,
        title: json['title'] as String,
        department: json['department'] as String? ?? '',
        location: json['location'] as String? ?? '',
        description: json['description'] as String? ?? '',
        requirements: json['requirements'] as String? ?? '',
        salaryMin: json['salary_min'] ?? json['salaryBand']?['min'] ?? 0,
        salaryMax: json['salary_max'] ?? json['salaryBand']?['max'] ?? 0,
        status: json['status'] as String? ?? 'active',
        applicationCount: json['applicationCount'] as int?,
        createdAt: json['created_at'] as String?,
      );
}

class Application {
  Application({
    required this.id,
    required this.jobId,
    required this.candidateName,
    required this.email,
    required this.phone,
    required this.education,
    required this.yearsExperience,
    required this.skills,
    required this.resumeUrl,
    required this.source,
    required this.stage,
    required this.stageLabel,
    this.jobTitle,
    this.referralCode,
    this.starred = false,
    this.tags = const [],
  });

  final String id;
  final String jobId;
  final String candidateName;
  final String email;
  final String phone;
  final String education;
  final num yearsExperience;
  final String skills;
  final String resumeUrl;
  final String source;
  final String stage;
  final String stageLabel;
  final String? jobTitle;
  final String? referralCode;
  final bool starred;
  final List<String> tags;

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        candidateName: json['candidate_name'] as String,
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        education: json['education'] as String? ?? '',
        yearsExperience: json['years_experience'] ?? 0,
        skills: json['skills'] as String? ?? '',
        resumeUrl: json['resume_url'] as String? ?? '',
        source: json['source'] as String? ?? '',
        stage: json['stage'] as String,
        stageLabel: json['stageLabel'] as String? ?? json['stage'] as String,
        jobTitle: json['job_title'] as String?,
        referralCode: json['referral_code'] as String?,
        starred: json['starred'] == true,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class TimelineItem {
  TimelineItem({
    required this.id,
    required this.action,
    required this.fromStage,
    required this.toStage,
    required this.note,
    required this.createdAt,
    this.userName,
  });

  final String id;
  final String action;
  final String? fromStage;
  final String? toStage;
  final String note;
  final String createdAt;
  final String? userName;

  factory TimelineItem.fromJson(Map<String, dynamic> json) => TimelineItem(
        id: json['id'] as String,
        action: json['action'] as String,
        fromStage: json['from_stage'] as String?,
        toStage: json['to_stage'] as String?,
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] as String,
        userName: json['user_name'] as String?,
      );
}

class Interview {
  Interview({
    required this.id,
    required this.applicationId,
    required this.interviewerId,
    required this.roundType,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.location,
    required this.status,
    this.candidateName,
    this.jobTitle,
  });

  final String id;
  final String applicationId;
  final String interviewerId;
  final String roundType;
  final String scheduledAt;
  final int durationMinutes;
  final String location;
  final String status;
  final String? candidateName;
  final String? jobTitle;

  factory Interview.fromJson(Map<String, dynamic> json) => Interview(
        id: json['id'] as String,
        applicationId: json['application_id'] as String,
        interviewerId: json['interviewer_id'] as String,
        roundType: json['round_type'] as String? ?? 'round1',
        scheduledAt: json['scheduled_at'] as String,
        durationMinutes: json['duration_minutes'] as int? ?? 60,
        location: json['location'] as String? ?? '',
        status: json['status'] as String? ?? 'scheduled',
        candidateName: json['candidate_name'] as String?,
        jobTitle: json['job_title'] as String?,
      );
}

class Offer {
  Offer({
    required this.id,
    required this.applicationId,
    required this.salary,
    required this.bonus,
    required this.status,
    required this.needsApproval,
    this.candidateName,
    this.jobTitle,
  });

  final String id;
  final String applicationId;
  final num salary;
  final num bonus;
  final String status;
  final bool needsApproval;
  final String? candidateName;
  final String? jobTitle;

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'] as String,
        applicationId: json['application_id'] as String,
        salary: json['salary'] ?? 0,
        bonus: json['bonus'] ?? 0,
        status: json['status'] as String,
        needsApproval: json['needsApproval'] == true || json['needs_approval'] == 1,
        candidateName: json['candidate_name'] as String?,
        jobTitle: json['job_title'] as String?,
      );
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.readFlag,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool readFlag;
  final String createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String? ?? 'system',
        readFlag: json['read_flag'] == 1 || json['readFlag'] == true,
        createdAt: json['created_at'] as String,
      );
}

class FunnelItem {
  FunnelItem({
    required this.stage,
    required this.label,
    required this.count,
    required this.conversionRate,
  });

  final String stage;
  final String label;
  final int count;
  final num conversionRate;

  factory FunnelItem.fromJson(Map<String, dynamic> json) => FunnelItem(
        stage: json['stage'] as String,
        label: json['label'] as String,
        count: json['count'] as int,
        conversionRate: json['conversionRate'] ?? 0,
      );
}

class SourceItem {
  SourceItem({required this.source, required this.count, required this.percentage});

  final String source;
  final int count;
  final num percentage;

  factory SourceItem.fromJson(Map<String, dynamic> json) => SourceItem(
        source: json['source'] as String,
        count: json['count'] as int,
        percentage: json['percentage'] ?? 0,
      );
}

class TalentPoolItem {
  TalentPoolItem({
    required this.id,
    required this.candidateName,
    required this.education,
    required this.yearsExperience,
    required this.skills,
    required this.starred,
    required this.tags,
    this.jobTitle,
  });

  final String id;
  final String candidateName;
  final String education;
  final num yearsExperience;
  final String skills;
  final bool starred;
  final List<String> tags;
  final String? jobTitle;

  factory TalentPoolItem.fromJson(Map<String, dynamic> json) => TalentPoolItem(
        id: json['id'] as String? ?? json['applicationId'] as String,
        candidateName: json['candidate_name'] as String,
        education: json['education'] as String? ?? '',
        yearsExperience: json['years_experience'] ?? 0,
        skills: json['skills'] as String? ?? '',
        starred: json['starred'] == true || json['starred'] == 1,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        jobTitle: json['job_title'] as String?,
      );
}

class ReferralStats {
  ReferralStats({
    required this.totalSuccess,
    required this.totalPoints,
    required this.rewardPerOnboard,
    required this.items,
  });

  final int totalSuccess;
  final int totalPoints;
  final int rewardPerOnboard;
  final List<Map<String, dynamic>> items;

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        totalSuccess: json['totalSuccess'] ?? json['successful_count'] ?? 0,
        totalPoints: json['totalPoints'] ?? json['total_points'] ?? 0,
        rewardPerOnboard: json['rewardPerOnboard'] ?? 5000,
        items: (json['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      );
}

const stageLabels = {
  'applied': '投递',
  'screening': '筛选',
  'written': '笔试',
  'round1': '一面',
  'round2': '二面',
  'offer': 'Offer',
  'onboarded': '入职',
  'rejected': '淘汰',
};

const pipelineStages = [
  'applied',
  'screening',
  'written',
  'round1',
  'round2',
  'offer',
  'onboarded',
  'rejected',
];
