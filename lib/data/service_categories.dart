import 'package:flutter/material.dart';

class ServiceCategory {
  const ServiceCategory(this.id, this.title, this.icon);
  final String id;
  final String title;
  final IconData icon;
}

const serviceCategories = <ServiceCategory>[
  ServiceCategory('motorcycle', 'تعمیرات موتور', Icons.two_wheeler),
  ServiceCategory('electrical', 'برق‌کاری', Icons.electrical_services),
  ServiceCategory('plumbing', 'لوله‌کشی', Icons.plumbing),
  ServiceCategory('welding', 'جوشکاری', Icons.handyman),
  ServiceCategory('construction', 'ساختمان', Icons.home_repair_service),
  ServiceCategory('painting', 'نقاشی', Icons.format_paint),
  ServiceCategory('cooling', 'سرمایش و گرمایش', Icons.ac_unit),
  ServiceCategory('other', 'سایر خدمات', Icons.more_horiz),
];

String categoryTitle(String id) {
  for (final item in serviceCategories) {
    if (item.id == id) return item.title;
  }
  return 'سایر خدمات';
}
