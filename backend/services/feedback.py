"""Generates simple Arabic, template-based feedback strings from metric scores.

Combines the relevant per-metric remarks (for any subscore that looks
concerning) into a single human-readable feedback_text. When nothing stands
out, a positive, encouraging message is returned instead.
"""
from models.session import Classification
from services.classifier import MetricScores

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: an assumption that any subscore below the
# midpoint (50/100) is "concerning enough" to surface a specific remark to
# the user; not yet clinically validated.
# Current value: 50
# Suggested range: [40 - 60]
# Impact: Lowering this threshold surfaces remarks more readily (more
# detailed feedback, but possibly noisier/more alarming); raising it
# surfaces remarks only for more severe deviations.
# ============================================================
CONCERN_THRESHOLD = 50.0

_F0_REMARK = "طبقة الصوت خارج المعدل الطبيعي"
_F0_SD_REMARK = "يُلاحظ تذبذب في ثبات نبرة الصوت أثناء نطق الحرف الممدود"
_JITTER_REMARK = "يُلاحظ ارتفاع في خشونة الصوت (Jitter)، يُنصح بمتابعة الجلسات بانتظام"
_SHIMMER_REMARK = "يُلاحظ عدم استقرار في شدة الصوت (Shimmer)، يُفضل تكرار التسجيل في بيئة هادئة"
_HNR_REMARK = "نقاء الصوت (HNR) أقل من المعتاد، أكثِر من شرب الماء وتجنّب التسجيل أثناء البحّة أو التعب"
_INTENSITY_REMARK = "شدة الصوت أثناء التسجيل غير ضمن المعدل المعتاد، حاول التحدث بصوت طبيعي وواضح"
_DURATION_REMARK = "مدة التسجيل قصيرة، حاول الإطالة في الجلسة القادمة"

_HEALTHY_REMARK = "المؤشرات الصوتية ضمن النطاق الطبيعي (سليم معرفياً)، استمر في المتابعة"
_AT_RISK_REMARK = "بعض المؤشرات تشير إلى احتمال ضعف إدراكي بسيط (MCI)، يُنصح بإجراء جلسات منتظمة ومتابعة طبيب مختص"
_SICK_REMARK = "المؤشرات الصوتية تستدعي اهتماماً أكبر، يُرجى مراجعة مختص في أقرب وقت ممكن"


def build_feedback_text(scores: MetricScores, classification: Classification) -> str:
    """Combine relevant per-metric remarks into a single Arabic feedback string."""
    remarks: list[str] = []

    if scores.f0_score < CONCERN_THRESHOLD:
        remarks.append(_F0_REMARK)
    if scores.f0_sd_score is not None and scores.f0_sd_score < CONCERN_THRESHOLD:
        remarks.append(_F0_SD_REMARK)
    if scores.jitter_score < CONCERN_THRESHOLD:
        remarks.append(_JITTER_REMARK)
    if scores.shimmer_score < CONCERN_THRESHOLD:
        remarks.append(_SHIMMER_REMARK)
    if scores.hnr_score is not None and scores.hnr_score < CONCERN_THRESHOLD:
        remarks.append(_HNR_REMARK)
    if scores.intensity_score < CONCERN_THRESHOLD:
        remarks.append(_INTENSITY_REMARK)
    if scores.duration_score < CONCERN_THRESHOLD:
        remarks.append(_DURATION_REMARK)

    if classification == Classification.healthy and not remarks:
        remarks.append(_HEALTHY_REMARK)
    elif classification == Classification.at_risk:
        remarks.append(_AT_RISK_REMARK)
    elif classification == Classification.sick:
        remarks.append(_SICK_REMARK)

    return " — ".join(remarks)
