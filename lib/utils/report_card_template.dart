import '../models/models.dart';

class ReportCardTemplate {
  static const String level1Section = 'سطح 1';
  static const String level2Section = 'سطح 2';
  static const String level3Section = 'سطح 3';
  static const String level4Section = 'سطح 4';
  static const String level5Section = 'سطح 5';
  static const String level6Section = 'سطح 6';
  static const String level7Section = 'سطح 7';

  // عناوین هر سطح
  static const Map<String, String> sectionTitles = {
    level1Section: 'آشنایی با آب و شناوری‌ها',
    level2Section: 'آموزش مقدماتی کرال سینه و پشت و پا دوچرخه',
    level3Section: 'آموزش تکمیلی کرال سینه و پشت و مقدماتی قورباغه',
    level4Section:
        'اصلاح تکنیک کرال سینه و پشت و تکمیلی قورباغه و مقدماتی پروانه',
    level5Section:
        'اصلاح تکنیک قورباغه و تکمیلی پروانه و آمادگی جهت شرکت در مسابقات کرال سینه و کرال پشت',
    level6Section:
        'اصلاح تکنیک پروانه و رکورد کرال سینه جهت آماده‌سازی نجات غریق و شرکت در مسابقات سه شنا اصلی (سینه - پشت - قورباغه)',
    level7Section:
        'رکورد 200 متر سینه و قورباغه 25 درصد کمتر از حداکثر رکورد نجات غریق و آماده‌سازی جهت شرکت در مسابقات چهار شنا اصلی',
  };

  // دریافت عنوان یک سطح
  static String getSectionTitle(String sectionName) {
    return sectionTitles[sectionName] ?? '';
  }

  // سطح 1 - آشنایی با آب و شناوری‌ها
  static List<TechniqueEvaluation> getLevel1Techniques() {
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

  // سطح 2 - آموزش مقدماتی کرال سینه و پشت و پا دوچرخه
  static List<TechniqueEvaluation> getLevel2Techniques() {
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

  // سطح 3 - آموزش تکمیلی کرال سینه و پشت و مقدماتی قورباغه
  static List<TechniqueEvaluation> getLevel3Techniques() {
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

  // سطح 4 - اصلاح تکنیک کرال سینه و پشت و تکمیلی قورباغه و مقدماتی پروانه
  static List<TechniqueEvaluation> getLevel4Techniques() {
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

  // سطح 5 - اصلاح تکنیک قورباغه و تکمیلی پروانه
  static List<TechniqueEvaluation> getLevel5Techniques() {
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

  // سطح 6 - اصلاح تکنیک پروانه و رکورد کرال سینه
  static List<TechniqueEvaluation> getLevel6Techniques() {
    return [
      TechniqueEvaluation(number: 1, techniqueName: 'تمرینات انتروال سینه'),
      TechniqueEvaluation(number: 2, techniqueName: 'رکورد 200 متر کرال سینه'),
      TechniqueEvaluation(
        number: 3,
        techniqueName: 'کرال سر بالا و قورباغه سر بالا 50 متر',
      ),
      TechniqueEvaluation(number: 4, techniqueName: '4*25 مختلط انفرادی'),
      TechniqueEvaluation(number: 5, techniqueName: 'زیر آبی 20 متر'),
      TechniqueEvaluation(
        number: 6,
        techniqueName: 'تمرینات استقامت سینه و قورباغه 400 متر',
      ),
      TechniqueEvaluation(number: 7, techniqueName: 'رکورد 100 متر قورباغه'),
      TechniqueEvaluation(number: 8, techniqueName: 'انواع قوس‌ها'),
      TechniqueEvaluation(number: 9, techniqueName: 'سالتو سینه و پشت'),
    ];
  }

  // سطح 7 - رکورد 200 متر سینه و قورباغه
  static List<TechniqueEvaluation> getLevel7Techniques() {
    return [
      TechniqueEvaluation(number: 1, techniqueName: '4*50 مختلط انفرادی'),
      TechniqueEvaluation(number: 2, techniqueName: 'تمرینات استقامت 800 متر'),
      TechniqueEvaluation(number: 3, techniqueName: 'شنا با مانع 100 متر'),
      TechniqueEvaluation(number: 4, techniqueName: 'شنا پهلو (قیچی) 100 متر'),
      TechniqueEvaluation(number: 5, techniqueName: 'پشت مقدماتی 100 متر'),
      TechniqueEvaluation(
        number: 6,
        techniqueName: 'تمرینات اینتروال پروانه و قورباغه',
      ),
      TechniqueEvaluation(number: 7, techniqueName: 'رکورد 400 متر سینه'),
      TechniqueEvaluation(
        number: 8,
        techniqueName: '2 دقیقه دوچرخه با دست بالا',
      ),
      TechniqueEvaluation(
        number: 9,
        techniqueName: 'تمرینات 10*25 قورباغه و پروانه',
      ),
    ];
  }

  // ایجاد تمام بخش‌ها
  static Map<String, SectionEvaluation> createAllSections() {
    return {
      level1Section: SectionEvaluation(
        sectionName: level1Section,
        techniques: getLevel1Techniques(),
      ),
      level2Section: SectionEvaluation(
        sectionName: level2Section,
        techniques: getLevel2Techniques(),
      ),
      level3Section: SectionEvaluation(
        sectionName: level3Section,
        techniques: getLevel3Techniques(),
      ),
      level4Section: SectionEvaluation(
        sectionName: level4Section,
        techniques: getLevel4Techniques(),
      ),
      level5Section: SectionEvaluation(
        sectionName: level5Section,
        techniques: getLevel5Techniques(),
      ),
      level6Section: SectionEvaluation(
        sectionName: level6Section,
        techniques: getLevel6Techniques(),
      ),
      level7Section: SectionEvaluation(
        sectionName: level7Section,
        techniques: getLevel7Techniques(),
      ),
    };
  }

  // لیست نام بخش‌ها به ترتیب
  static List<String> getSectionNames() {
    return [
      level1Section,
      level2Section,
      level3Section,
      level4Section,
      level5Section,
      level6Section,
      level7Section,
    ];
  }

  // تعداد کل تکنیک‌ها
  static int getTotalTechniquesCount() {
    return 63; // 9 تکنیک × 7 سطح
  }
}
