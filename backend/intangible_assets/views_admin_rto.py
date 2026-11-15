"""
API ادمین برای دیدن لیست دانشجویان RTO + دارایی‌هاشون + پاسخ‌ها + فایل‌ها
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .rto_models import RTOStudent, RTOStudentInfo
from .valuation_models import AssetValuation


class AdminRTOStudentsListView(APIView):
    """
    GET: لیست دانشجویان + دارایی‌هاشون + پاسخ‌ها + فایل‌ها
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not (hasattr(request.user, 'role') and request.user.role in ['super_admin', 'org_admin']):
            return Response({'error': 'دسترسی ندارید'}, status=403)

        students = RTOStudent.objects.prefetch_related('assets__asset').order_by('-created_at')

        results = []
        for student in students:
            assets_data = []
            
            for info in student.assets.all():
                asset = info.asset
                
                answers = []
                final_score = 0
                valuation = AssetValuation.objects.filter(asset=asset, status='completed').first()
                if valuation:
                    final_score = float(valuation.final_score or 0)
                    for ans in valuation.answers.select_related('question').all():
                        has_file = bool(ans.evidence_document)
                        file_url = ans.evidence_document.url if has_file else None
                        
                        answers.append({
                            'id': ans.id,
                            'question_text': ans.question.question_text if ans.question else '',
                            'dimension': ans.question.dimension.name if ans.question and ans.question.dimension else '',
                            'score': ans.score,
                            'evidence': ans.evidence or '',
                            'has_file': has_file,
                            'file_url': file_url,
                            'file_name': ans.evidence_document.name.split('/')[-1] if has_file else None,
                        })
                
                assets_data.append({
                    'asset_id': asset.id,
                    'asset_name': asset.asset_name,
                    'asset_type': asset.asset_type.name if asset.asset_type else None,
                    'final_score': final_score,
                    'answers': answers,
                    'total_answers': len(answers),
                    'total_files': sum(1 for a in answers if a['has_file']),
                    'created_at': info.created_at,
                })
            
            results.append({
                'id': student.id,
                'student_name': student.student_name,
                'student_family': student.student_family,
                'student_full_name': f"{student.student_name} {student.student_family}",
                'student_id': student.student_id,
                'student_phone': student.student_phone,
                'student_email': student.student_email,
                'created_at': student.created_at,
                'assets': assets_data,
                'total_assets': len(assets_data),
            })

        return Response({
            'count': len(results),
            'results': results,
        })
