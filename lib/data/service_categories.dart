import 'package:flutter/material.dart';

class ServiceCategory {
  const ServiceCategory(this.id, this.title, this.icon);
  final String id;
  final String title;
  final IconData icon;
}

/// Main groups shown on home/search. Detailed specialties are child rows in
/// Supabase and are offered when a worker chooses their professional skill.
const serviceCategories = <ServiceCategory>[
  ServiceCategory('motorcycle', 'تعمیرات موتورسیکلت', Icons.two_wheeler),
  ServiceCategory('automotive', 'خودرو', Icons.directions_car),
  ServiceCategory('heavy_machinery', 'ماشین‌آلات سنگین', Icons.agriculture),
  ServiceCategory('machining', 'تراشکاری و ماشین‌کاری', Icons.precision_manufacturing),
  ServiceCategory('spare_parts', 'لوازم یدکی', Icons.settings),
  ServiceCategory('construction', 'ساختمان و مصالح', Icons.home_repair_service),
  ServiceCategory('electrical', 'برق و الکترونیک', Icons.electrical_services),
  ServiceCategory('plumbing', 'تأسیسات و لوله‌کشی', Icons.plumbing),
  ServiceCategory('welding', 'جوشکاری و فلزکاری', Icons.handyman),
  ServiceCategory('cooling', 'سرمایش و گرمایش', Icons.ac_unit),
  ServiceCategory('painting', 'نقاشی و دکوراسیون', Icons.format_paint),
  ServiceCategory('services', 'خدمات عمومی', Icons.miscellaneous_services),
  ServiceCategory('other', 'سایر خدمات', Icons.more_horiz),
];

String categoryTitle(String id) {
  for (final item in serviceCategories) {
    if (item.id == id) return item.title;
  }
  return 'سایر خدمات';
}
