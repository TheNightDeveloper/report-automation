import '../models/models.dart';

class ReportCardTemplate {
  static const String preschoolSection = 'مخصوص دانش‌آموزان پیش دبستانی';
  static const String year1Section = 'سال تحصیلی اول';
  static const String year2Section = 'سال تحصیلی دوم';
  static const String year3Section = 'سال تحصیلی سوم';
  static const String year4Section = 'سال تحصیلی چهارم';

  // بخش پیش دبستانی - 9 تکنیک
  static List<TechniqueEvaluation> getPreschoolTechniques() {
    return [
      TechniqueEvaluation(number: 1, techniqueName: 'دویدن در آب'),
      TechniqueEvaluation(number: 2, techniqueName: 'تخلیه هوا'),
      TechniqueEvaluation(number: 3, techniqueName: 'فلوت سینه'),
      TechniqueEvaluation(number: 4, techniqueName: 'فلوت پشت'),
      TechniqueEvaluation(number: 5, techniqueName: 'لاک پشت'),
      TechniqueEvaluation(number: 6, techniqueName: 'سرخوردن روی سینه'),
      TechniqueEvaluation(number: 7, techniqueName: 'سرخوردن روی پشت'),
      TechniqueEvaluation(number: 8, techniqueName: 'پریدن'),
      TechniqueEvaluation(number: 9, techniqueName: 'استارت نشسته'),
    ];
  }

  // سال اول - 9 تکنیک
  static List<TechniqueEvaluation> getYear1Techniques() {
    return [
      TechniqueEvaluation(number: 1, techniqueName: 'پای کرال سینه'),
      TechniqueEvaluation(number: 2, techniqueName: 'پای کرال پشت'),
      TechniqueEvaluation(number: 3, techniqueName: 'نفس گیری کرال سینه'),
      TechniqueEvaluation(number: 4, techniqueName: 'پای پهلو (راست و چپ)'),
      TechniqueEvaluation(number: 5, techniqueName: 'مهارت شناوری در عمیق'),
      TechniqueEvaluation(number: 6, techniqueName: 'استارت 1 و 2'),
      TechniqueEvaluation(number: 7, techniqueName: 'چرخش از سینه به پشت'),
      TechniqueEvaluation(number: 8, techniqueName: 'پریدن در عمیق'),
      TechniqueEvaluation(number: 9, techniqueName: 'چرخش از پشت به سینه'),
    ];
  }

  // سال دوم - 9 تکنیک
  static List<TechniqueEvaluation> getYear2Techniques() {
    return [
      TechniqueEvaluation(number: 1, techniqueName: 'دست کرال سینه'),
      TechniqueEvaluation(number: 2, techniqueName: 'دست کرال پشت'),
      TechniqueEvaluation(
        number: 3,
        techniqueName: 'هماهنگی کرال سینه با هوا گیری',
      ),
      TechniqueEvaluation(number: 4, techniqueName: 'هماهنگی کرال پشت'),
      TechniqueEvaluation(number: 5, techniqueName: 'استارت کرال پشت'),
      TechniqueEvaluation(number: 6, techniqueName: 'استارت کرال سینه'),
      TechniqueEvaluation(number: 7, techniqueName: 'دست مقدماتی قورباغه'),
      TechniqueEvaluation(number: 8, techniqueName: 'پای مقدماتی قورباغه'),
      TechniqueEvaluation(
        number: 9,
        techniqueName: 'برگشت کرال سینه و کرال پشت',
      ),
    ];
  }

  // سال سوم - 9 تکنیک
  static List<TechniqueEvaluation> getYear3Techniques() {
    return [
      TechniqueEvaluation(
        number: 1,
        techniqueName: '50 متر کرال سینه هواگیری هر دو طرف',
      ),
      TechniqueEvaluation(
        number: 2,
        techniqueName: '50 متر کرال پشت همراه با استارت و برگشت',
      ),
      TechniqueEvaluation(number: 3, techniqueName: 'دست قورباغه'),
      TechniqueEvaluation(number: 4, techniqueName: 'پای قورباغه'),
      TechniqueEvaluation(number: 5, techniqueName: 'هماهنگی شنا قورباغه'),
      TechniqueEvaluation(number: 6, techniqueName: 'استارت قورباغه'),
      TechniqueEvaluation(number: 7, techniqueName: 'برگشت قورباغه'),
      TechniqueEvaluation(number: 8, techniqueName: 'حرکت موج'),
      TechniqueEvaluation(number: 9, techniqueName: 'مقدماتی سالتو سینه'),
    ];
  }

  // سال چهارم - 9 تکنیک
  static List<TechniqueEvaluation> getYear4Techniques() {
    return [
      TechniqueEvaluation(
        number: 1,
        techniqueName: '50 متر قورباغه همراه با استارت و برگشت',
      ),
      TechniqueEvaluation(number: 2, techniqueName: 'دست پروانه'),
      TechniqueEvaluation(number: 3, techniqueName: 'نفس گیری پروانه'),
      TechniqueEvaluation(number: 4, techniqueName: 'هماهنگی پروانه'),
      TechniqueEvaluation(number: 5, techniqueName: 'استارت پروانه'),
      TechniqueEvaluation(number: 6, techniqueName: 'برگشت پروانه'),
      TechniqueEvaluation(number: 7, techniqueName: 'تمرینات سرعتی'),
      TechniqueEvaluation(number: 8, techniqueName: 'تمرینات استقامتی'),
      TechniqueEvaluation(
        number: 9,
        techniqueName: '200 متر کرال سینه 100 متر کرال پشت',
      ),
    ];
  }

  // ایجاد تمام بخش‌ها
  static Map<String, SectionEvaluation> createAllSections() {
    return {
      preschoolSection: SectionEvaluation(
        sectionName: preschoolSection,
        techniques: getPreschoolTechniques(),
      ),
      year1Section: SectionEvaluation(
        sectionName: year1Section,
        techniques: getYear1Techniques(),
      ),
      year2Section: SectionEvaluation(
        sectionName: year2Section,
        techniques: getYear2Techniques(),
      ),
      year3Section: SectionEvaluation(
        sectionName: year3Section,
        techniques: getYear3Techniques(),
      ),
      year4Section: SectionEvaluation(
        sectionName: year4Section,
        techniques: getYear4Techniques(),
      ),
    };
  }

  // لیست نام بخش‌ها به ترتیب
  static List<String> getSectionNames() {
    return [
      preschoolSection,
      year1Section,
      year2Section,
      year3Section,
      year4Section,
    ];
  }

  // تعداد کل تکنیک‌ها
  static int getTotalTechniquesCount() {
    return 45; // 9 تکنیک × 5 بخش
  }
}
